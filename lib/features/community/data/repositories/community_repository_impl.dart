import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/core/storage/storage_remote_datasource.dart';
import 'package:plenty/features/community/data/datasources/community_remote_datasource.dart';
import 'package:plenty/features/community/domain/models/community_post.dart';
import 'package:plenty/features/community/domain/models/post_comment_model.dart';
import 'package:plenty/features/community/domain/repositories/community_repository.dart';
import 'package:plenty/features/profile/domain/models/badge_item.dart';
import 'package:sqflite/sqflite.dart';

/// Simplified implementation of [ICommunityRepository] backed purely by Cloud Firestore.
/// SQLite is strictly reserved for storing offline pending uploads when internet is unreachable,
/// which are uploaded to Firebase as soon as internet connectivity is restored.
class CommunityRepositoryImpl implements ICommunityRepository {
  final DatabaseHelper _dbHelper;
  final CommunityRemoteDataSource _remoteDataSource;
  final StorageRemoteDataSource? _storageRemoteDataSource;

  CommunityRepositoryImpl({
    DatabaseHelper? dbHelper,
    CommunityRemoteDataSource? remoteDataSource,
    StorageRemoteDataSource? storageRemoteDataSource,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _remoteDataSource =
            remoteDataSource ?? FirestoreCommunityRemoteDataSourceImpl(),
        _storageRemoteDataSource = storageRemoteDataSource;

  @override
  Future<Result<List<CommunityPost>>> getPosts({
    String category = 'all',
    int? currentUserId,
  }) async {
    try {
      final user = await _getUserContext(currentUserId);

      // 1. Sync any pending offline uploads to Firebase if internet is active
      await syncPendingPosts();

      // 2. Fetch directly from Firebase
      try {
        final remotePosts = await _remoteDataSource.getPosts(
          category: category,
          currentUserId: user.stringId,
        );

        // Check if there are any remaining unsynced pending posts in SQLite
        final pendingPosts = await _getPendingPosts(
          category: category,
          currentUserId: user.numericId,
        );

        if (pendingPosts.isEmpty) {
          return Success(remotePosts);
        }

        // Merge any unsynced local pending posts at the top of the feed
        final remoteIds = remotePosts.map((p) => p.id).toSet();
        final combined = <CommunityPost>[
          ...pendingPosts.where((p) => !remoteIds.contains(p.id)),
          ...remotePosts,
        ];
        return Success(combined);
      } catch (e) {
        // Offline fallback: load only user's pending offline posts from SQLite
        final pendingPosts = await _getPendingPosts(
          category: category,
          currentUserId: user.numericId,
        );
        if (pendingPosts.isNotEmpty) {
          return Success(pendingPosts);
        }
        return Error(NetworkFailure('Gagal memuat postingan: ${e.toString()}'));
      }
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<CommunityPost>> createPost(
    CommunityPost post, {
    int? userId,
  }) async {
    try {
      final user = await _getUserContext(userId);

      String effectiveAuthorName = post.authorName;
      String? effectiveAvatar = post.authorAvatar;
      if (effectiveAuthorName.isEmpty ||
          effectiveAuthorName == 'Pecinta Tanaman' ||
          effectiveAuthorName == 'Penggemar Tanaman') {
        effectiveAuthorName = user.name;
        effectiveAvatar ??= user.avatar;
      }

      final normalizedCat = _normalizeCategory(post.category) ?? 'pertanyaan';

      // Deduplicate shared badges
      if (post.attachedBadge != null) {
        final hasShared = await hasUserSharedBadge(
          post.attachedBadge!.id,
          userId: user.numericId,
        );
        if (hasShared.dataOrNull == true) {
          return const Error(
            ValidationFailure(
              'Lencana ini sudah pernah Anda bagikan ke Komunitas.',
            ),
          );
        }
      }

      // Upload image to Firebase Cloud Storage if present and not already a remote URL
      String? effectiveImageUrl = post.imagePath;
      if (_storageRemoteDataSource != null &&
          effectiveImageUrl != null &&
          effectiveImageUrl.trim().isNotEmpty &&
          !effectiveImageUrl.startsWith('http://') &&
          !effectiveImageUrl.startsWith('https://') &&
          !effectiveImageUrl.startsWith('assets/')) {
        try {
          final uploaded = await _storageRemoteDataSource.uploadFile(
            filePath: effectiveImageUrl,
            destinationPath:
                'community_posts/${post.id}/cover_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          if (uploaded.startsWith('http://') ||
              uploaded.startsWith('https://')) {
            effectiveImageUrl = uploaded;
          }
        } catch (_) {}
      }

      final created = post.copyWith(
        userId: user.numericId,
        authorId: user.stringId,
        authorName: effectiveAuthorName,
        authorAvatar: effectiveAvatar,
        category: normalizedCat,
        imagePath: effectiveImageUrl,
        likesCount: 0,
        isLiked: false,
        isAuthor: true,
      );

      // Attempt immediate upload to Firebase
      try {
        await _remoteDataSource.savePost(created, userId: user.stringId);
        // Upload any older pending uploads in background
        await syncPendingPosts();
        return Success(created);
      } catch (_) {
        // Offline / no internet: persist in SQLite queue until internet returns
        await _savePendingUpload(created, user.numericId);
        return Success(created);
      }
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<CommunityPost>> updatePost(
    CommunityPost post, {
    int? userId,
  }) async {
    try {
      final user = await _getUserContext(userId);
      final normalizedCat = _normalizeCategory(post.category) ?? 'pertanyaan';

      // Upload image to Firebase Cloud Storage if present and not already a remote URL
      String? effectiveImageUrl = post.imagePath;
      if (_storageRemoteDataSource != null &&
          effectiveImageUrl != null &&
          effectiveImageUrl.trim().isNotEmpty &&
          !effectiveImageUrl.startsWith('http://') &&
          !effectiveImageUrl.startsWith('https://') &&
          !effectiveImageUrl.startsWith('assets/')) {
        try {
          final uploaded = await _storageRemoteDataSource.uploadFile(
            filePath: effectiveImageUrl,
            destinationPath:
                'community_posts/${post.id}/cover_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          if (uploaded.startsWith('http://') ||
              uploaded.startsWith('https://')) {
            effectiveImageUrl = uploaded;
          }
        } catch (_) {}
      }

      // 1. Check if post is currently a pending offline upload in SQLite
      final db = await _dbHelper.database;
      final pending = await db.query(
        DatabaseHelper.tableCommunityPosts,
        where: 'id = ?',
        whereArgs: [post.id],
      );

      if (pending.isNotEmpty) {
        final pendingUserId = pending.first['user_id'] as int?;
        final pendingUserIdStr = pending.first['user_id']?.toString();
        final isPendingOwner = (pendingUserId != null &&
                (pendingUserId == user.numericId || pendingUserId == userId)) ||
            (pendingUserIdStr != null && pendingUserIdStr == user.stringId);
        if (!isPendingOwner) {
          return const Error(
            ValidationFailure(
              'Anda tidak dapat mengedit postingan milik pengguna lain',
            ),
          );
        }

        await db.update(
          DatabaseHelper.tableCommunityPosts,
          {
            'category': normalizedCat,
            'caption': post.content,
            'image_url': effectiveImageUrl,
          },
          where: 'id = ?',
          whereArgs: [post.id],
        );
        return Success(post.copyWith(
          category: normalizedCat,
          imagePath: effectiveImageUrl,
          isAuthor: true,
        ));
      }

      // 2. Otherwise update directly on Firebase
      try {
        final existing = await _remoteDataSource.getPostById(
          post.id,
          currentUserId: user.stringId,
        );
        if (existing == null) {
          return const Error(NotFoundFailure('Postingan tidak ditemukan'));
        }
        final isOwner = existing.isAuthor ||
            (existing.authorId != null && existing.authorId == user.stringId) ||
            (existing.userId != null &&
                (existing.userId == user.numericId || existing.userId == userId));
        if (!isOwner) {
          return const Error(
            ValidationFailure(
              'Anda tidak dapat mengedit postingan milik pengguna lain',
            ),
          );
        }

        final updatedPost = post.copyWith(
          category: normalizedCat,
          imagePath: effectiveImageUrl,
          isAuthor: true,
        );
        await _remoteDataSource.updatePost(updatedPost, userId: user.stringId);
        return Success(updatedPost);
      } catch (e) {
        return Error(NetworkFailure('Gagal memperbarui postingan: ${e.toString()}'));
      }
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deletePost(String postId, {int? userId}) async {
    try {
      final user = await _getUserContext(userId);

      // 1. Check if post is in local SQLite pending queue
      final db = await _dbHelper.database;
      final pending = await db.query(
        DatabaseHelper.tableCommunityPosts,
        where: 'id = ?',
        whereArgs: [postId],
      );

      if (pending.isNotEmpty) {
        final pendingUserId = pending.first['user_id'] as int?;
        final pendingUserIdStr = pending.first['user_id']?.toString();
        final isPendingOwner = (pendingUserId != null &&
                (pendingUserId == user.numericId || pendingUserId == userId)) ||
            (pendingUserIdStr != null && pendingUserIdStr == user.stringId);
        if (!isPendingOwner) {
          return const Error(
            ValidationFailure(
              'Anda tidak dapat menghapus postingan milik pengguna lain',
            ),
          );
        }
        await db.delete(
          DatabaseHelper.tableCommunityPosts,
          where: 'id = ?',
          whereArgs: [postId],
        );
        return const Success(null);
      }

      // 2. Otherwise delete directly from Firebase
      try {
        final existing = await _remoteDataSource.getPostById(
          postId,
          currentUserId: user.stringId,
        );
        if (existing != null) {
          final isOwner = existing.isAuthor ||
              (existing.authorId != null && existing.authorId == user.stringId) ||
              (existing.userId != null &&
                  (existing.userId == user.numericId || existing.userId == userId));
          if (!isOwner) {
            return const Error(
              ValidationFailure(
                'Anda tidak dapat menghapus postingan milik pengguna lain',
              ),
            );
          }
        }

        await _remoteDataSource.deletePost(postId, userId: user.stringId);
        return const Success(null);
      } catch (e) {
        return Error(NetworkFailure('Gagal menghapus postingan: ${e.toString()}'));
      }
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<CommunityPost>> toggleLike(String postId, {int? userId}) async {
    try {
      final user = await _getUserContext(userId);

      final isNowLiked =
          await _remoteDataSource.toggleLike(postId, user.stringId);
      final updatedPost = await _remoteDataSource.getPostById(
        postId,
        currentUserId: user.stringId,
      );

      if (updatedPost != null) {
        return Success(updatedPost);
      }

      return Success(CommunityPost(
        id: postId,
        userId: user.numericId,
        authorName: 'Penggemar Tanaman',
        timeAgo: 'Baru saja',
        category: 'pertanyaan',
        content: '',
        likesCount: isNowLiked ? 1 : 0,
        isLiked: isNowLiked,
        createdAt: DateTime.now(),
      ));
    } catch (e) {
      return Error(NetworkFailure('Gagal mengubah suka: ${e.toString()}'));
    }
  }

  @override
  Future<Result<bool>> hasUserSharedBadge(String badgeId, {int? userId}) async {
    try {
      final user = await _getUserContext(userId);

      // 1. Check directly on Firebase
      try {
        final shared = await _remoteDataSource.hasUserSharedBadge(
          badgeId,
          user.stringId,
        );
        if (shared) {
          return const Success(true);
        }
      } catch (_) {}

      // 2. Check if user has an offline pending post in SQLite with this badge
      try {
        final db = await _dbHelper.database;
        final pending = await db.query(
          DatabaseHelper.tableCommunityPosts,
          where: 'user_id = ? AND badge_id = ?',
          whereArgs: [user.numericId, badgeId],
          limit: 1,
        );
        if (pending.isNotEmpty) {
          return const Success(true);
        }
      } catch (_) {}

      return const Success(false);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<PostCommentModel>>> getComments(String postId) async {
    try {
      final comments = await _remoteDataSource.getComments(postId);
      return Success(comments);
    } catch (e) {
      return Error(NetworkFailure('Gagal memuat komentar: ${e.toString()}'));
    }
  }

  @override
  Future<Result<PostCommentModel>> addComment({
    required String postId,
    required String content,
    int? userId,
    String? authorName,
    String? authorAvatarUrl,
  }) async {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      return const Error(ValidationFailure('Komentar tidak boleh kosong'));
    }

    try {
      final user = await _getUserContext(userId);

      String effectiveAuthorName = authorName ?? '';
      String? effectiveAvatar = authorAvatarUrl;
      if (effectiveAuthorName.isEmpty ||
          effectiveAuthorName == 'Teman Plenty' ||
          effectiveAuthorName == 'Penggemar Tanaman') {
        effectiveAuthorName = user.name;
        effectiveAvatar ??= user.avatar;
      }

      final commentId =
          'cm_${DateTime.now().millisecondsSinceEpoch}_${user.numericId}';
      final now = DateTime.now();

      final comment = PostCommentModel(
        id: commentId,
        postId: postId,
        userId: user.stringId,
        authorName: effectiveAuthorName,
        authorAvatarUrl: effectiveAvatar,
        content: trimmedContent,
        createdAt: now,
      );

      await _remoteDataSource.saveComment(comment);
      return Success(comment);
    } catch (e) {
      return Error(NetworkFailure('Gagal mengirim komentar: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void>> deleteComment({
    required String postId,
    required String commentId,
    int? userId,
  }) async {
    try {
      await _remoteDataSource.deleteComment(postId, commentId);
      return const Success(null);
    } catch (e) {
      return Error(NetworkFailure('Gagal menghapus komentar: ${e.toString()}'));
    }
  }

  /// Uploads any pending offline posts from SQLite to Firebase, then removes them from SQLite.
  @override
  Future<void> syncPendingPosts() async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.rawQuery('''
        SELECT 
          p.*,
          b.title as badge_title,
          b.description as badge_desc,
          b.icon_name as badge_icon,
          b.tier_name as badge_tier,
          b.level as badge_level,
          b.target_total as badge_total,
          b.bg_color_hex as badge_bg_hex,
          b.accent_color_hex as badge_accent_hex
        FROM ${DatabaseHelper.tableCommunityPosts} p
        LEFT JOIN ${DatabaseHelper.tableBadges} b ON p.badge_id = b.id
        ORDER BY p.created_at ASC;
      ''');

      if (rows.isEmpty) return;

      for (final row in rows) {
        final post = _mapRowToCommunityPost(row);
        final userId = row['user_id']?.toString();
        var postToUpload = post;
        if (_storageRemoteDataSource != null &&
            post.imagePath != null &&
            post.imagePath!.trim().isNotEmpty &&
            !post.imagePath!.startsWith('http://') &&
            !post.imagePath!.startsWith('https://') &&
            !post.imagePath!.startsWith('assets/')) {
          try {
            final uploadedUrl = await _storageRemoteDataSource.uploadFile(
              filePath: post.imagePath!,
              destinationPath:
                  'community_posts/${post.id}/cover_${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
            if (uploadedUrl.startsWith('http://') ||
                uploadedUrl.startsWith('https://')) {
              postToUpload = post.copyWith(imagePath: uploadedUrl);
            }
          } catch (_) {}
        }
        try {
          await _remoteDataSource.savePost(postToUpload, userId: userId);
          // Successfully uploaded to Firebase -> delete from local pending storage
          await db.delete(
            DatabaseHelper.tableCommunityPosts,
            where: 'id = ?',
            whereArgs: [post.id],
          );
        } catch (_) {
          // If internet fails during sync, stop and retain for next sync attempt
          break;
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> seedInitialPosts() async {}

  // ---------------------------------------------------------------------------
  // Internal Helpers for SQLite Offline Upload Storage & User Context
  // ---------------------------------------------------------------------------

  Future<({int numericId, String stringId, String name, String? avatar})>
      _getUserContext([int? explicitId]) async {
    int numericId = explicitId ?? 1;
    String stringId = numericId.toString();
    String name = 'Penggemar Tanaman';
    String? avatar;

    try {
      final activeUser = await PreferenceHandler.getUser();
      if (activeUser != null) {
        if (explicitId == null &&
            activeUser.numericId != null &&
            activeUser.numericId != 0) {
          numericId = activeUser.numericId!;
        }
        if (activeUser.id != null && activeUser.id!.isNotEmpty) {
          stringId = activeUser.id!;
        }
        if (activeUser.username.isNotEmpty) {
          name = activeUser.username;
        } else if (activeUser.displayName.isNotEmpty) {
          name = activeUser.displayName;
        }
        avatar = activeUser.avatarUrl;
      }
    } catch (_) {}

    return (numericId: numericId, stringId: stringId, name: name, avatar: avatar);
  }

  Future<void> _savePendingUpload(CommunityPost post, int numericUserId) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        DatabaseHelper.tableCommunityPosts,
        {
          'id': post.id,
          'user_id': numericUserId,
          'category': _normalizeCategory(post.category) ?? 'pertanyaan',
          'caption': post.content,
          'image_url': post.imagePath,
          'badge_id': post.attachedBadge?.id,
          'kudos_count': 0,
          'is_liked': 0,
          'comment_count': post.commentsCount,
          'created_at': post.createdAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  Future<List<CommunityPost>> _getPendingPosts({
    String category = 'all',
    int? currentUserId,
  }) async {
    try {
      final db = await _dbHelper.database;
      final normalizedCategory = _normalizeCategory(category);

      String query = '''
        SELECT 
          p.*,
          b.title as badge_title,
          b.description as badge_desc,
          b.icon_name as badge_icon,
          b.tier_name as badge_tier,
          b.level as badge_level,
          b.target_total as badge_total,
          b.bg_color_hex as badge_bg_hex,
          b.accent_color_hex as badge_accent_hex
        FROM ${DatabaseHelper.tableCommunityPosts} p
        LEFT JOIN ${DatabaseHelper.tableBadges} b ON p.badge_id = b.id
      ''';
      final args = <dynamic>[];
      if (normalizedCategory != null) {
        query += ' WHERE LOWER(p.category) = ?';
        args.add(normalizedCategory);
      }
      query += ' ORDER BY p.created_at DESC;';

      final rows = await db.rawQuery(query, args);
      return rows
          .map((row) => _mapRowToCommunityPost(row, currentUserId))
          .toList();
    } catch (_) {
      return [];
    }
  }

  CommunityPost _mapRowToCommunityPost(
    Map<String, dynamic> row, [
    int? currentUserId,
  ]) {
    final createdAtStr =
        row['created_at'] as String? ?? DateTime.now().toIso8601String();
    final createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now();

    BadgeItem? attachedBadge;
    if (row['badge_id'] != null) {
      attachedBadge = BadgeItem(
        id: row['badge_id'] as String,
        title: row['badge_title'] as String? ?? '',
        desc: row['badge_desc'] as String? ?? '',
        iconName: row['badge_icon'] as String? ?? 'sprout',
        isUnlocked: true,
        level: (row['badge_level'] as int?) ?? 1,
        progress: (row['badge_progress'] as int?) ?? 1,
        total: (row['badge_total'] as int?) ?? 1,
        bgColorHex: row['badge_bg_hex'] as String? ?? '#EBF7F1',
        accentColorHex: row['badge_accent_hex'] as String? ?? '#2D6A4F',
        tierName: row['badge_tier'] as String? ?? '',
      );
    }

    final postUserId = row['user_id'] as int? ?? 1;
    final authorId = row['user_id']?.toString();
    final isAuthor = currentUserId == null || postUserId == currentUserId;

    return CommunityPost(
      id: row['id'] as String? ?? '',
      userId: postUserId,
      authorId: authorId,
      authorName: row['author_name'] as String? ?? 'Penggemar Tanaman',
      authorAvatar: null,
      timeAgo: CommunityPost.formatTimeAgo(createdAt),
      category: _normalizeCategory(row['category'] as String?) ?? 'pertanyaan',
      content: row['caption'] as String? ?? '',
      imagePath: row['image_url'] as String?,
      attachedBadge: attachedBadge,
      likesCount: (row['kudos_count'] as int?) ?? 0,
      isLiked: false,
      isAuthor: isAuthor,
      commentsCount: (row['comment_count'] as int?) ?? 0,
      createdAt: createdAt,
    );
  }

  static String? _normalizeCategory(String? category) {
    if (category == null) return null;
    final lower = category.toLowerCase().trim();
    if (lower == 'all' || lower == 'semua') return null;
    if (lower.contains('tanya') || lower == 'pertanyaan') return 'pertanyaan';
    if (lower.contains('capai') || lower == 'pencapaian') return 'pencapaian';
    if (lower.contains('tip') || lower == 'tips') return 'tips';
    return lower;
  }
}
