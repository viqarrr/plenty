import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/domain/models/badge_item.dart';
import 'package:plenty/features/community/data/repositories/community_repository_impl.dart';
import 'package:plenty/features/community/domain/models/community_post.dart';
import 'package:plenty/features/community/domain/repositories/community_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late ICommunityRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper.forTesting(
      'community_repo_test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    await dbHelper.deleteDb();
    final db = await dbHelper.database;
    await db.insert(
      'users',
      {
        'id': 2,
        'email': 'user2@plenty.app',
        'username': 'user_two',
        'password': '',
        'display_name': 'User Two',
        'streak_count': 0,
        'longest_streak': 0,
        'total_xp': 0,
        'level': 1,
        'unlocked_badges_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    repository = CommunityRepositoryImpl(dbHelper: dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('CommunityRepository Unit Tests', () {
    test('getPosts auto-seeds default posts and new user has isLiked false on all', () async {
      final postsRes = await repository.getPosts(currentUserId: 2);
      final posts = postsRes.dataOrNull ?? [];
      expect(posts.isNotEmpty, isTrue);
      expect(posts.length, greaterThanOrEqualTo(3));
      // For a new user (ID: 2), all posts should have isLiked == false
      expect(posts.every((p) => p.isLiked == false), isTrue);
    });

    test('getPosts filters accurately by category', () async {
      final tanyaPostsRes = await repository.getPosts(category: 'pertanyaan');
      final tanyaPosts = tanyaPostsRes.dataOrNull ?? [];
      expect(tanyaPosts.every((p) => p.category == 'pertanyaan'), isTrue);

      final capaiPostsRes = await repository.getPosts(category: 'pencapaian');
      final capaiPosts = capaiPostsRes.dataOrNull ?? [];
      expect(capaiPosts.every((p) => p.category == 'pencapaian'), isTrue);

      final tipsPostsRes = await repository.getPosts(category: 'tips');
      final tipsPosts = tipsPostsRes.dataOrNull ?? [];
      expect(tipsPosts.every((p) => p.category == 'tips'), isTrue);
    });

    test('createPost inserts new post and retrieves it with user attribution', () async {
      final newPost = CommunityPost(
        id: 'test_post_1',
        authorName: 'rian_plant',
        timeAgo: 'Baru saja',
        category: 'pertanyaan',
        content: 'Bagaimana cara mengatasi kutu putih pada aglonema?',
        createdAt: DateTime.now(),
      );

      final createdRes = await repository.createPost(newPost, userId: 1);
      final created = createdRes.dataOrNull!;
      expect(created.id, 'test_post_1');

      final postsRes = await repository.getPosts(category: 'pertanyaan');
      final posts = postsRes.dataOrNull ?? [];
      expect(posts.any((p) => p.id == 'test_post_1'), isTrue);
    });

    test('createPost with attached badge saves and retrieves badge relation', () async {
      const badge = BadgeItem(
        id: 'first_plant',
        title: 'Adopsi Pertama',
        desc: 'Mengadopsi tanaman pertama',
        iconName: 'eco',
        isUnlocked: true,
        level: 1,
        progress: 1,
        total: 1,
        bgColorHex: '#EBF7F1',
        accentColorHex: '#2D6A4F',
      );

      final postWithBadge = CommunityPost(
        id: 'badge_post_1',
        authorName: 'alex_green',
        timeAgo: 'Baru saja',
        category: 'pencapaian',
        content: 'Berhasil membuka lencana Adopsi Pertama!',
        attachedBadge: badge,
        createdAt: DateTime.now(),
      );

      await repository.createPost(postWithBadge, userId: 1);

      final postsRes = await repository.getPosts(category: 'pencapaian');
      final posts = postsRes.dataOrNull ?? [];
      final found = posts.firstWhere((p) => p.id == 'badge_post_1');
      expect(found.attachedBadge, isNotNull);
      expect(found.attachedBadge?.id, 'first_plant');
    });

    test('toggleLike isolates like states between different users', () async {
      final initialPostsRes = await repository.getPosts(currentUserId: 1);
      final targetPost = initialPostsRes.dataOrNull!.first;

      // User 1 likes post
      final user1PostRes = await repository.toggleLike(targetPost.id, userId: 1);
      final user1Post = user1PostRes.dataOrNull!;
      expect(user1Post.isLiked, isTrue);

      // User 2 checks post -> should NOT be liked for user 2
      final user2PostsRes = await repository.getPosts(currentUserId: 2);
      final user2Posts = user2PostsRes.dataOrNull ?? [];
      final user2Post = user2Posts.firstWhere((p) => p.id == targetPost.id);
      expect(user2Post.isLiked, isFalse);
      expect(user2Post.likesCount, user1Post.likesCount);

      // User 2 likes post as well -> count increments
      final user2PostAfterLikeRes = await repository.toggleLike(targetPost.id, userId: 2);
      final user2PostAfterLike = user2PostAfterLikeRes.dataOrNull!;
      expect(user2PostAfterLike.isLiked, isTrue);
      expect(user2PostAfterLike.likesCount, user1Post.likesCount + 1);

      // User 1 unlikes post -> user 2 still has isLiked == true
      final user1PostAfterUnlikeRes = await repository.toggleLike(targetPost.id, userId: 1);
      final user1PostAfterUnlike = user1PostAfterUnlikeRes.dataOrNull!;
      expect(user1PostAfterUnlike.isLiked, isFalse);

      final user2PostsFinalRes = await repository.getPosts(currentUserId: 2);
      final user2PostsFinal = user2PostsFinalRes.dataOrNull ?? [];
      final user2PostFinal = user2PostsFinal.firstWhere((p) => p.id == targetPost.id);
      expect(user2PostFinal.isLiked, isTrue);
    });

    test('updatePost updates post content and category', () async {
      final newPost = CommunityPost(
        id: 'edit_test_post',
        authorName: 'rian_plant',
        timeAgo: 'Baru saja',
        category: 'pertanyaan',
        content: 'Konten sebelum diedit',
        createdAt: DateTime.now(),
      );

      await repository.createPost(newPost, userId: 1);

      final updateDraft = newPost.copyWith(
        category: 'tips',
        content: 'Konten berhasil diperbarui dan diedit!',
      );

      final updateRes = await repository.updatePost(updateDraft, userId: 1);
      expect(updateRes.isSuccess, isTrue);
      final updated = updateRes.dataOrNull!;
      expect(updated.category, 'tips');
      expect(updated.content, 'Konten berhasil diperbarui dan diedit!');

      final postsRes = await repository.getPosts(category: 'tips');
      final posts = postsRes.dataOrNull ?? [];
      final found = posts.firstWhere((p) => p.id == 'edit_test_post');
      expect(found.content, 'Konten berhasil diperbarui dan diedit!');
    });

    test('deletePost removes post from database', () async {
      final newPost = CommunityPost(
        id: 'delete_test_post',
        authorName: 'rian_plant',
        timeAgo: 'Baru saja',
        category: 'tips',
        content: 'Postingan ini akan segera dihapus',
        createdAt: DateTime.now(),
      );

      await repository.createPost(newPost, userId: 1);

      final deleteRes = await repository.deletePost('delete_test_post', userId: 1);
      expect(deleteRes.isSuccess, isTrue);

      final postsRes = await repository.getPosts();
      final posts = postsRes.dataOrNull ?? [];
      expect(posts.any((p) => p.id == 'delete_test_post'), isFalse);
    });
  });
}
