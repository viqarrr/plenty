import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/auth/domain/models/user_model.dart';
import 'package:plenty/features/community/data/datasources/community_remote_datasource.dart';
import 'package:plenty/features/community/domain/models/community_post.dart';
import 'package:plenty/features/community/domain/models/post_comment_model.dart';
import 'package:plenty/features/community/domain/repositories/community_repository.dart';
import 'package:plenty/features/profile/domain/models/badge_item.dart';
import 'package:sqflite/sqflite.dart';

/// Implementation of ICommunityRepository with SQLite persistence and Cloud Firestore sync.
class CommunityRepositoryImpl implements ICommunityRepository {
  final DatabaseHelper _dbHelper;
  final CommunityRemoteDataSource? _remoteDataSource;
  bool _isInitialized = false;

  CommunityRepositoryImpl({
    DatabaseHelper? dbHelper,
    CommunityRemoteDataSource? remoteDataSource,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _remoteDataSource = remoteDataSource;

  static const List<Map<String, dynamic>> _seedPosts = [
    {
      'id': 'cp_seed_1',
      'user_id': 999,
      'category': 'pertanyaan',
      'caption':
          'Ujung daun Monstera menguning dan agak layu setelah dipindah ke balkon. Apakah ini tanda kelebihan sinar matahari atau overwatering? Mohon masukannya para plant parents!',
      'image_url': null,
      'badge_id': null,
      'kudos_count': 0,
      'comment_count': 0,
      'created_at': '2026-08-23T14:30:00.000Z',
    },
    {
      'id': 'cp_seed_2',
      'user_id': 999,
      'category': 'pencapaian',
      'caption':
          'Hore! Berhasil menjaga konsistensi menyiram dan merawat tanaman selama 7 hari tanpa terputus! 🌿💧',
      'image_url': null,
      'badge_id': 'water_streak',
      'kudos_count': 0,
      'comment_count': 0,
      'created_at': '2026-08-22T10:15:00.000Z',
    },
    {
      'id': 'cp_seed_3',
      'user_id': 999,
      'category': 'tips',
      'caption':
          'Tips perbanyakan Sirih Gading (Golden Pothos): Potong batang 1 cm di bawah ruas akar (node), rendam di air bersih dan ganti 3 hari sekali. Akar akan tumbuh lebat dalam 2 minggu!',
      'image_url': null,
      'badge_id': null,
      'kudos_count': 0,
      'comment_count': 0,
      'created_at': '2026-08-21T08:00:00.000Z',
    },
  ];

  @override
  Future<Result<void>> seedInitialPosts() async {
    if (_isInitialized) return const Success(null);
    try {
      final db = await _dbHelper.database;

      await db.insert(DatabaseHelper.tableUsers, {
        'id': 999,
        'email': 'community@plenty.app',
        'username': 'komunitas_plenty',
        'password': '',
        'display_name': 'Komunitas Plenty',
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      final tableInfo = await db.rawQuery(
        'PRAGMA table_info(${DatabaseHelper.tableCommunityPosts})',
      );
      final columnNames = tableInfo.map((col) => col['name'] as String).toSet();

      if (!columnNames.contains('badge_id')) {
        await db.execute(
          'ALTER TABLE ${DatabaseHelper.tableCommunityPosts} ADD COLUMN badge_id TEXT;',
        );
      }

      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${DatabaseHelper.tablePostLikes} (
          post_id TEXT NOT NULL,
          user_id INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          PRIMARY KEY (post_id, user_id),
          FOREIGN KEY (post_id) REFERENCES ${DatabaseHelper.tableCommunityPosts} (id) ON DELETE CASCADE,
          FOREIGN KEY (user_id) REFERENCES ${DatabaseHelper.tableUsers} (id) ON DELETE CASCADE
        );
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${DatabaseHelper.tablePostComments} (
          id TEXT PRIMARY KEY,
          post_id TEXT NOT NULL,
          user_id INTEGER NOT NULL,
          content TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (post_id) REFERENCES ${DatabaseHelper.tableCommunityPosts} (id) ON DELETE CASCADE,
          FOREIGN KEY (user_id) REFERENCES ${DatabaseHelper.tableUsers} (id) ON DELETE CASCADE
        );
      ''');

      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM ${DatabaseHelper.tableCommunityPosts}',
        ),
      );

      if (count == null || count == 0) {
        final batch = db.batch();
        for (final post in _seedPosts) {
          batch.insert(
            DatabaseHelper.tableCommunityPosts,
            post,
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        await batch.commit(noResult: true);
      }
      _isInitialized = true;
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<CommunityPost>>> getPosts({
    String category = 'all',
    int? currentUserId,
  }) async {
    try {
      final db = await _dbHelper.database;
      await seedInitialPosts();

      int effectiveUserId = currentUserId ?? 1;
      String stringUserId = effectiveUserId.toString();
      UserModel? activeUser;
      try {
        activeUser = await PreferenceHandler.getUser();
        if (activeUser != null) {
          if (currentUserId == null &&
              activeUser.numericId != null &&
              activeUser.numericId != 0) {
            effectiveUserId = activeUser.numericId!;
          }
          if (activeUser.id != null && activeUser.id!.isNotEmpty) {
            stringUserId = activeUser.id!;
          }
        }
      } catch (_) {}

      // If remote data source is provided, sync remote posts to SQLite cache
      if (_remoteDataSource != null) {
        try {
          final remotePosts = await _remoteDataSource.getPosts(
            category: category,
            currentUserId: stringUserId,
          );
          for (final p in remotePosts) {
            await db.insert(
              DatabaseHelper.tableUsers,
              {
                'id': p.userId ?? 999,
                'email': '',
                'username': p.authorName,
                'password': '',
                'display_name': p.authorName,
                'avatar_url': p.authorAvatar,
                'created_at': DateTime.now().toIso8601String(),
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
            await db.insert(
              DatabaseHelper.tableCommunityPosts,
              {
                'id': p.id,
                'user_id': p.userId ?? effectiveUserId,
                'category': _normalizeCategory(p.category) ?? 'pertanyaan',
                'caption': p.content,
                'image_url': p.imagePath,
                'badge_id': p.attachedBadge?.id,
                'kudos_count': p.likesCount,
                'comment_count': p.commentsCount,
                'created_at': p.createdAt.toIso8601String(),
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            if (p.isLiked) {
              await db.insert(
                DatabaseHelper.tablePostLikes,
                {
                  'post_id': p.id,
                  'user_id': effectiveUserId,
                  'created_at': DateTime.now().toIso8601String(),
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
          if (remotePosts.isNotEmpty) {
            return Success(remotePosts);
          }
        } catch (_) {
          // Offline fallback
        }
      }

      String query =
          '''
        SELECT 
          p.id,
          p.user_id,
          p.category,
          p.caption,
          p.image_url,
          p.badge_id,
          p.kudos_count,
          p.comment_count,
          p.created_at,
          u.display_name,
          u.username,
          u.avatar_url,
          b.title as badge_title,
          b.description as badge_desc,
          b.icon_name as badge_icon,
          b.tier_name as badge_tier,
          b.level as badge_level,
          b.target_total as badge_total,
          b.bg_color_hex as badge_bg_hex,
          b.accent_color_hex as badge_accent_hex,
          ub.current_progress as badge_progress,
          ub.is_unlocked as badge_is_unlocked,
          ub.unlocked_at as badge_unlocked_at,
          CASE WHEN pl.user_id IS NOT NULL THEN 1 ELSE 0 END as is_liked
        FROM ${DatabaseHelper.tableCommunityPosts} p
        LEFT JOIN ${DatabaseHelper.tableUsers} u ON p.user_id = u.id
        LEFT JOIN ${DatabaseHelper.tableBadges} b ON p.badge_id = b.id
        LEFT JOIN ${DatabaseHelper.tableUserBadges} ub 
          ON p.badge_id = ub.badge_id AND ub.user_id = p.user_id
        LEFT JOIN ${DatabaseHelper.tablePostLikes} pl
          ON pl.post_id = p.id AND pl.user_id = ?
      ''';

      final normalizedCategory = _normalizeCategory(category);
      final args = <dynamic>[effectiveUserId];

      if (normalizedCategory != null) {
        query += ' WHERE LOWER(p.category) = ?';
        args.add(normalizedCategory);
      }

      query += ' ORDER BY p.created_at DESC;';

      final rows = await db.rawQuery(query, args);
      final posts = rows
          .map((row) => _mapRowToCommunityPost(row, effectiveUserId))
          .toList();
      return Success(posts);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<CommunityPost>> toggleLike(String postId, {int? userId}) async {
    try {
      final db = await _dbHelper.database;
      await seedInitialPosts();

      int effectiveUserId = userId ?? 1;
      if (userId == null) {
        try {
          final activeUser = await PreferenceHandler.getUser();
          if (activeUser != null &&
              activeUser.numericId != null &&
              activeUser.numericId != 0) {
            effectiveUserId = activeUser.numericId!;
          }
        } catch (_) {}
      }

      final existing = await db.query(
        DatabaseHelper.tablePostLikes,
        where: 'post_id = ? AND user_id = ?',
        whereArgs: [postId, effectiveUserId],
      );

      bool isNowLiked;
      if (existing.isNotEmpty) {
        await db.delete(
          DatabaseHelper.tablePostLikes,
          where: 'post_id = ? AND user_id = ?',
          whereArgs: [postId, effectiveUserId],
        );
        isNowLiked = false;
      } else {
        await db.insert(
          DatabaseHelper.tablePostLikes,
          {
            'post_id': postId,
            'user_id': effectiveUserId,
            'created_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        isNowLiked = true;
      }

      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseHelper.tablePostLikes} WHERE post_id = ?',
        [postId],
      );
      final currentLikesCount = (countResult.first['count'] as int?) ?? 0;

      await db.update(
        DatabaseHelper.tableCommunityPosts,
        {'kudos_count': currentLikesCount},
        where: 'id = ?',
        whereArgs: [postId],
      );

      final updatedPostsResult = await getPosts(currentUserId: effectiveUserId);
      final updatedPosts = updatedPostsResult.dataOrNull ?? [];
      final post = updatedPosts.firstWhere(
        (p) => p.id == postId,
        orElse: () => CommunityPost(
          id: postId,
          authorName: 'Penggemar Tanaman',
          timeAgo: 'Baru saja',
          category: 'pertanyaan',
          content: '',
          likesCount: currentLikesCount,
          isLiked: isNowLiked,
          createdAt: DateTime.now(),
        ),
      );
      final remote = _remoteDataSource;
      if (remote != null) {
        try {
          String stringUserId = effectiveUserId.toString();
          final activeUser = await PreferenceHandler.getUser();
          final activeUid = activeUser?.id;
          if (activeUid != null && activeUid.isNotEmpty) {
            stringUserId = activeUid;
          }
          await remote.toggleLike(postId, stringUserId);
        } catch (_) {}
      }

      return Success(post);
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
      final db = await _dbHelper.database;
      await seedInitialPosts();

      int effectiveUserId = userId ?? 1;
      String effectiveAuthorName = post.authorName;
      String? effectiveAvatar = post.authorAvatar;

      try {
        final activeUser = await PreferenceHandler.getUser();
        if (activeUser != null) {
          if (userId == null &&
              activeUser.numericId != null &&
              activeUser.numericId != 0) {
            effectiveUserId = activeUser.numericId!;
          }
          if (post.authorName.isEmpty ||
              post.authorName == 'Pecinta Tanaman' ||
              post.authorName == 'Penggemar Tanaman') {
            if (activeUser.username.isNotEmpty) {
              effectiveAuthorName = activeUser.username;
            } else if (activeUser.displayName.isNotEmpty) {
              effectiveAuthorName = activeUser.displayName;
            }
            effectiveAvatar = activeUser.avatarUrl;
          }
        }
      } catch (_) {}

      final normalizedCat = _normalizeCategory(post.category) ?? 'pertanyaan';

      if (post.attachedBadge != null) {
        final existingBadgePosts = await db.query(
          DatabaseHelper.tableCommunityPosts,
          where: 'user_id = ? AND badge_id = ?',
          whereArgs: [effectiveUserId, post.attachedBadge!.id],
        );
        if (existingBadgePosts.isNotEmpty) {
          return const Error(
            ValidationFailure(
              'Lencana ini sudah pernah Anda bagikan ke Komunitas.',
            ),
          );
        }
      }

      await db.insert(
        DatabaseHelper.tableCommunityPosts,
        {
          'id': post.id,
          'user_id': effectiveUserId,
          'category': normalizedCat,
          'caption': post.content,
          'image_url': post.imagePath,
          'badge_id': post.attachedBadge?.id,
          'kudos_count': 0,
          'comment_count': post.commentsCount,
          'created_at': post.createdAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final created = post.copyWith(
        userId: effectiveUserId,
        authorName: effectiveAuthorName,
        authorAvatar: effectiveAvatar,
        category: normalizedCat,
        likesCount: 0,
        isLiked: false,
        isAuthor: true,
      );

      final remote = _remoteDataSource;
      if (remote != null) {
        try {
          String stringUserId = effectiveUserId.toString();
          final activeUser = await PreferenceHandler.getUser();
          final activeUid = activeUser?.id;
          if (activeUid != null && activeUid.isNotEmpty) {
            stringUserId = activeUid;
          }
          await remote.savePost(created, userId: stringUserId);
        } catch (_) {}
      }

      return Success(created);
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
      final db = await _dbHelper.database;
      await seedInitialPosts();

      int effectiveUserId = userId ?? 1;
      try {
        final activeUser = await PreferenceHandler.getUser();
        if (activeUser != null &&
            userId == null &&
            activeUser.numericId != null &&
            activeUser.numericId != 0) {
          effectiveUserId = activeUser.numericId!;
        }
      } catch (_) {}

      final existing = await db.query(
        DatabaseHelper.tableCommunityPosts,
        where: 'id = ?',
        whereArgs: [post.id],
      );

      if (existing.isEmpty) {
        return const Error(NotFoundFailure('Postingan tidak ditemukan'));
      }

      final postUserId = existing.first['user_id'] as int?;
      if (postUserId != null && postUserId != effectiveUserId) {
        return const Error(
          ValidationFailure(
            'Anda tidak dapat mengedit postingan milik pengguna lain',
          ),
        );
      }

      final normalizedCat = _normalizeCategory(post.category) ?? 'pertanyaan';

      final updatedRows = await db.update(
        DatabaseHelper.tableCommunityPosts,
        {
          'category': normalizedCat,
          'caption': post.content,
          'image_url': post.imagePath,
        },
        where: 'id = ?',
        whereArgs: [post.id],
      );

      if (updatedRows == 0) {
        return const Error(NotFoundFailure('Postingan tidak ditemukan'));
      }

      final postsRes = await getPosts(currentUserId: effectiveUserId);
      final posts = postsRes.dataOrNull ?? [];
      final updatedPost = posts.firstWhere(
        (p) => p.id == post.id,
        orElse: () => post.copyWith(category: normalizedCat, isAuthor: true),
      );

      final remote = _remoteDataSource;
      if (remote != null) {
        try {
          String stringUserId = effectiveUserId.toString();
          final activeUser = await PreferenceHandler.getUser();
          final activeUid = activeUser?.id;
          if (activeUid != null && activeUid.isNotEmpty) {
            stringUserId = activeUid;
          }
          await remote.updatePost(updatedPost, userId: stringUserId);
        } catch (_) {}
      }

      return Success(updatedPost);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deletePost(String postId, {int? userId}) async {
    try {
      final db = await _dbHelper.database;
      await seedInitialPosts();

      int? effectiveUserId = userId;
      if (effectiveUserId == null) {
        try {
          final activeUser = await PreferenceHandler.getUser();
          if (activeUser != null &&
              activeUser.numericId != null &&
              activeUser.numericId != 0) {
            effectiveUserId = activeUser.numericId;
          }
        } catch (_) {}
      }

      final existing = await db.query(
        DatabaseHelper.tableCommunityPosts,
        where: 'id = ?',
        whereArgs: [postId],
      );

      if (existing.isEmpty) {
        return const Error(NotFoundFailure('Postingan tidak ditemukan'));
      }

      final postUserId = existing.first['user_id'] as int?;
      if (effectiveUserId != null &&
          postUserId != null &&
          postUserId != effectiveUserId) {
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

      final remote = _remoteDataSource;
      if (remote != null) {
        try {
          await remote.deletePost(postId);
        } catch (_) {}
      }

      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<bool>> hasUserSharedBadge(String badgeId, {int? userId}) async {
    try {
      final db = await _dbHelper.database;
      await seedInitialPosts();

      int effectiveUserId = userId ?? 1;
      try {
        final activeUser = await PreferenceHandler.getUser();
        if (activeUser != null &&
            userId == null &&
            activeUser.numericId != null &&
            activeUser.numericId != 0) {
          effectiveUserId = activeUser.numericId!;
        }
      } catch (_) {}

      final existing = await db.query(
        DatabaseHelper.tableCommunityPosts,
        where: 'user_id = ? AND badge_id = ?',
        whereArgs: [effectiveUserId, badgeId],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        return const Success(true);
      }

      final remote = _remoteDataSource;
      if (remote != null) {
        try {
          String stringUserId = effectiveUserId.toString();
          final activeUser = await PreferenceHandler.getUser();
          final activeUid = activeUser?.id;
          if (activeUid != null && activeUid.isNotEmpty) {
            stringUserId = activeUid;
          }
          final remoteHasShared =
              await remote.hasUserSharedBadge(badgeId, stringUserId);
          if (remoteHasShared) {
            return const Success(true);
          }
        } catch (_) {}
      }

      return const Success(false);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<PostCommentModel>>> getComments(String postId) async {
    try {
      final db = await _dbHelper.database;
      await seedInitialPosts();

      final remote = _remoteDataSource;
      if (remote != null) {
        try {
          final remoteComments = await remote.getComments(postId);
          for (final c in remoteComments) {
            final commentUid = int.tryParse(c.userId) ?? 1;
            await db.insert(
              DatabaseHelper.tableUsers,
              {
                'id': commentUid,
                'email': '',
                'username': c.authorName,
                'password': '',
                'display_name': c.authorName,
                'avatar_url': c.authorAvatarUrl,
                'created_at': DateTime.now().toIso8601String(),
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
            await db.insert(
              DatabaseHelper.tablePostComments,
              {
                'id': c.id,
                'post_id': c.postId,
                'user_id': commentUid,
                'content': c.content,
                'created_at': c.createdAt.toIso8601String(),
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          if (remoteComments.isNotEmpty) {
            return Success(remoteComments);
          }
        } catch (_) {
          // Offline fallback
        }
      }

      final rows = await db.rawQuery('''
        SELECT 
          c.id,
          c.post_id,
          c.user_id,
          c.content,
          c.created_at,
          u.display_name,
          u.username,
          u.avatar_url
        FROM ${DatabaseHelper.tablePostComments} c
        LEFT JOIN ${DatabaseHelper.tableUsers} u ON c.user_id = u.id
        WHERE c.post_id = ?
        ORDER BY c.created_at ASC
      ''', [postId]);

      final comments = rows.map((row) {
        final username = row['username'] as String?;
        final displayName = row['display_name'] as String?;
        final authorName = (username != null && username.isNotEmpty)
            ? username
            : (displayName != null && displayName.isNotEmpty
                ? displayName
                : 'Teman Plenty');

        final createdAtStr =
            row['created_at'] as String? ?? DateTime.now().toIso8601String();
        final createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now();

        return PostCommentModel(
          id: row['id'] as String? ?? '',
          postId: row['post_id'] as String? ?? postId,
          userId: (row['user_id'] as int? ?? 1).toString(),
          authorName: authorName,
          authorAvatarUrl: row['avatar_url'] as String?,
          content: row['content'] as String? ?? '',
          createdAt: createdAt,
        );
      }).toList();

      return Success(comments);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
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
    try {
      final trimmedContent = content.trim();
      if (trimmedContent.isEmpty) {
        return const Error(ValidationFailure('Komentar tidak boleh kosong'));
      }

      final db = await _dbHelper.database;
      await seedInitialPosts();

      int effectiveUserId = userId ?? 1;
      String stringUserId = effectiveUserId.toString();
      String effectiveAuthorName = authorName ?? '';
      String? effectiveAvatar = authorAvatarUrl;

      try {
        final activeUser = await PreferenceHandler.getUser();
        if (activeUser != null) {
          if (userId == null &&
              activeUser.numericId != null &&
              activeUser.numericId != 0) {
            effectiveUserId = activeUser.numericId!;
          }
          if (activeUser.id != null && activeUser.id!.isNotEmpty) {
            stringUserId = activeUser.id!;
          }
          if (effectiveAuthorName.isEmpty ||
              effectiveAuthorName == 'Teman Plenty' ||
              effectiveAuthorName == 'Penggemar Tanaman') {
            if (activeUser.username.isNotEmpty) {
              effectiveAuthorName = activeUser.username;
            } else if (activeUser.displayName.isNotEmpty) {
              effectiveAuthorName = activeUser.displayName;
            }
            effectiveAvatar = activeUser.avatarUrl;
          }
        }
      } catch (_) {}

      if (effectiveAuthorName.isEmpty) {
        effectiveAuthorName = 'Penggemar Tanaman';
      }

      final commentId =
          'cm_${DateTime.now().millisecondsSinceEpoch}_$effectiveUserId';
      final now = DateTime.now();

      await db.insert(
        DatabaseHelper.tablePostComments,
        {
          'id': commentId,
          'post_id': postId,
          'user_id': effectiveUserId,
          'content': trimmedContent,
          'created_at': now.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Increment comment_count on post
      await db.rawUpdate('''
        UPDATE ${DatabaseHelper.tableCommunityPosts}
        SET comment_count = comment_count + 1
        WHERE id = ?
      ''', [postId]);

      final comment = PostCommentModel(
        id: commentId,
        postId: postId,
        userId: stringUserId,
        authorName: effectiveAuthorName,
        authorAvatarUrl: effectiveAvatar,
        content: trimmedContent,
        createdAt: now,
      );

      final remote = _remoteDataSource;
      if (remote != null) {
        try {
          await remote.saveComment(comment);
        } catch (_) {}
      }

      return Success(comment);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteComment({
    required String postId,
    required String commentId,
    int? userId,
  }) async {
    try {
      final db = await _dbHelper.database;
      await seedInitialPosts();

      int? effectiveUserId = userId;
      if (effectiveUserId == null) {
        try {
          final activeUser = await PreferenceHandler.getUser();
          if (activeUser != null &&
              activeUser.numericId != null &&
              activeUser.numericId != 0) {
            effectiveUserId = activeUser.numericId;
          }
        } catch (_) {}
      }

      final existing = await db.query(
        DatabaseHelper.tablePostComments,
        where: 'id = ?',
        whereArgs: [commentId],
      );

      if (existing.isEmpty) {
        return const Error(NotFoundFailure('Komentar tidak ditemukan'));
      }

      final commentUserId = existing.first['user_id'] as int?;
      if (effectiveUserId != null &&
          commentUserId != null &&
          commentUserId != effectiveUserId) {
        return const Error(
          ValidationFailure(
            'Anda tidak dapat menghapus komentar milik pengguna lain',
          ),
        );
      }

      await db.delete(
        DatabaseHelper.tablePostComments,
        where: 'id = ?',
        whereArgs: [commentId],
      );

      // Decrement comment_count on post
      await db.rawUpdate('''
        UPDATE ${DatabaseHelper.tableCommunityPosts}
        SET comment_count = CASE WHEN comment_count > 0 THEN comment_count - 1 ELSE 0 END
        WHERE id = ?
      ''', [postId]);

      final remote = _remoteDataSource;
      if (remote != null) {
        try {
          await remote.deleteComment(postId, commentId);
        } catch (_) {}
      }

      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
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
    if (row['badge_id'] != null && row['badge_title'] != null) {
      final iconName = row['badge_icon'] as String? ?? 'sprout';
      final bgHex = row['badge_bg_hex'] as String? ?? '#EBF7F1';
      final accentHex = row['badge_accent_hex'] as String? ?? '#2D6A4F';

      attachedBadge = BadgeItem(
        id: row['badge_id'] as String,
        title: row['badge_title'] as String? ?? '',
        desc: row['badge_desc'] as String? ?? '',
        iconName: iconName,
        isUnlocked: (row['badge_is_unlocked'] as int?) == 1 || true,
        unlockedDate: row['badge_unlocked_at'] as String?,
        level: (row['badge_level'] as int?) ?? 1,
        progress: (row['badge_progress'] as int?) ?? 1,
        total: (row['badge_total'] as int?) ?? 1,
        bgColorHex: bgHex,
        accentColorHex: accentHex,
        tierName: row['badge_tier'] as String? ?? '',
      );
    }

    final username = row['username'] as String?;
    final displayName = row['display_name'] as String?;
    final authorName = (username != null && username.isNotEmpty)
        ? username
        : (displayName != null && displayName.isNotEmpty
              ? displayName
              : 'Penggemar Tanaman');

    final postUserId = row['user_id'] as int? ?? 1;
    final isAuthor = currentUserId != null && postUserId == currentUserId;

    return CommunityPost(
      id: row['id'] as String? ?? '',
      userId: postUserId,
      authorName: authorName,
      authorAvatar: row['avatar_url'] as String?,
      timeAgo: CommunityPost.formatTimeAgo(createdAt),
      category: _normalizeCategory(row['category'] as String?) ?? 'pertanyaan',
      content: row['caption'] as String? ?? '',
      imagePath: row['image_url'] as String?,
      attachedBadge: attachedBadge,
      likesCount: (row['kudos_count'] as int?) ?? 0,
      isLiked: ((row['is_liked'] as int?) ?? 0) == 1,
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
