import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/features/community/data/repositories/community_repository_impl.dart';
import 'package:plenty/features/community/domain/models/community_post.dart';
import 'package:plenty/features/community/domain/repositories/community_repository.dart';
import 'package:plenty/features/profile/domain/models/badge_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'fake_community_remote_datasource.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late FakeCommunityRemoteDataSource fakeRemote;
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
    await db.insert('users', {
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
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    fakeRemote = FakeCommunityRemoteDataSource();
    repository = CommunityRepositoryImpl(
      dbHelper: dbHelper,
      remoteDataSource: fakeRemote,
    );
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('CommunityRepository Firebase-backed Operations', () {
    test('getPosts returns posts from Firebase filtered by category', () async {
      final post1 = CommunityPost(
        id: 'p_tanya',
        authorName: 'Rian',
        timeAgo: 'Baru saja',
        category: 'pertanyaan',
        content: 'Tanya siram?',
        createdAt: DateTime.now(),
      );
      final post2 = CommunityPost(
        id: 'p_tips',
        authorName: 'Alex',
        timeAgo: 'Baru saja',
        category: 'tips',
        content: 'Tips pupuk',
        createdAt: DateTime.now(),
      );

      await repository.createPost(post1, userId: 1);
      await repository.createPost(post2, userId: 1);

      final tanyaRes = await repository.getPosts(category: 'pertanyaan');
      final tanyaPosts = tanyaRes.dataOrNull ?? [];
      expect(tanyaPosts.length, 1);
      expect(tanyaPosts.first.id, 'p_tanya');

      final tipsRes = await repository.getPosts(category: 'tips');
      final tipsPosts = tipsRes.dataOrNull ?? [];
      expect(tipsPosts.length, 1);
      expect(tipsPosts.first.id, 'p_tips');

      final allRes = await repository.getPosts(category: 'all');
      expect(allRes.dataOrNull?.length, 2);
    });

    test('createPost saves post directly to Firebase when online', () async {
      final newPost = CommunityPost(
        id: 'test_post_1',
        authorName: 'rian_plant',
        timeAgo: 'Baru saja',
        category: 'pertanyaan',
        content: 'Bagaimana cara mengatasi kutu putih pada aglonema?',
        createdAt: DateTime.now(),
      );

      final createdRes = await repository.createPost(newPost, userId: 1);
      expect(createdRes.isSuccess, isTrue);

      // Verify post exists on remote Firebase datasource
      expect(fakeRemote.posts.containsKey('test_post_1'), isTrue);

      // Verify SQLite tableCommunityPosts does NOT store online posts
      final db = await dbHelper.database;
      final localRows = await db.query(DatabaseHelper.tableCommunityPosts);
      expect(localRows.isEmpty, isTrue);
    });

    test('createPost with attached badge saves badge details to Firebase', () async {
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
      expect(found.attachedBadge?.title, 'Adopsi Pertama');
    });

    test('toggleLike updates like status directly on Firebase', () async {
      final post = CommunityPost(
        id: 'post_like_test',
        authorName: 'Botanist',
        timeAgo: 'Baru saja',
        category: 'tips',
        content: 'Tips daun rimbun',
        likesCount: 0,
        createdAt: DateTime.now(),
      );
      await repository.createPost(post, userId: 1);

      // User 1 likes
      final likedRes = await repository.toggleLike('post_like_test', userId: 1);
      final likedPost = likedRes.dataOrNull!;
      expect(likedPost.isLiked, isTrue);
      expect(likedPost.likesCount, 1);

      // User 2 fetches posts
      final user2Posts = await repository.getPosts(currentUserId: 2);
      final user2Post = user2Posts.dataOrNull!.firstWhere((p) => p.id == 'post_like_test');
      expect(user2Post.isLiked, isFalse);
      expect(user2Post.likesCount, 1);

      // User 1 unlikes
      final unlikedRes = await repository.toggleLike('post_like_test', userId: 1);
      expect(unlikedRes.dataOrNull!.isLiked, isFalse);
      expect(unlikedRes.dataOrNull!.likesCount, 0);
    });

    test('updatePost updates post on Firebase', () async {
      final post = CommunityPost(
        id: 'edit_test_post',
        authorName: 'rian_plant',
        timeAgo: 'Baru saja',
        category: 'pertanyaan',
        content: 'Konten sebelum diedit',
        userId: 1,
        createdAt: DateTime.now(),
      );
      await repository.createPost(post, userId: 1);

      final updateDraft = post.copyWith(
        category: 'tips',
        content: 'Konten berhasil diperbarui dan diedit!',
      );

      final updateRes = await repository.updatePost(updateDraft, userId: 1);
      expect(updateRes.isSuccess, isTrue);
      expect(updateRes.dataOrNull!.content, 'Konten berhasil diperbarui dan diedit!');
      expect(updateRes.dataOrNull!.category, 'tips');

      expect(fakeRemote.posts['edit_test_post']?.content,
          'Konten berhasil diperbarui dan diedit!');
    });

    test('deletePost removes post from Firebase for author', () async {
      final post = CommunityPost(
        id: 'delete_test_post',
        authorName: 'rian_plant',
        timeAgo: 'Baru saja',
        category: 'tips',
        content: 'Postingan ini akan segera dihapus',
        userId: 1,
        createdAt: DateTime.now(),
      );
      await repository.createPost(post, userId: 1);

      final deleteRes = await repository.deletePost('delete_test_post', userId: 1);
      expect(deleteRes.isSuccess, isTrue);

      expect(fakeRemote.posts.containsKey('delete_test_post'), isFalse);
    });

    test('addComment, getComments, and deleteComment manage comments purely on Firebase', () async {
      final post = CommunityPost(
        id: 'comm_post',
        authorName: 'rian_plant',
        timeAgo: 'Baru saja',
        category: 'pertanyaan',
        content: 'Diskusi tanaman',
        createdAt: DateTime.now(),
      );
      await repository.createPost(post, userId: 1);

      final addRes = await repository.addComment(
        postId: 'comm_post',
        content: 'Komentar pertama',
        userId: 2,
        authorName: 'User Two',
      );
      expect(addRes.isSuccess, isTrue);
      final comment = addRes.dataOrNull!;
      expect(comment.content, 'Komentar pertama');
      expect(comment.authorName, 'User Two');

      final getRes = await repository.getComments('comm_post');
      expect(getRes.isSuccess, isTrue);
      expect(getRes.dataOrNull?.length, 1);

      final delRes = await repository.deleteComment(
        postId: 'comm_post',
        commentId: comment.id,
        userId: 2,
      );
      expect(delRes.isSuccess, isTrue);

      final getAfterDel = await repository.getComments('comm_post');
      expect(getAfterDel.dataOrNull?.isEmpty, isTrue);
    });

    test('hasUserSharedBadge checks badge sharing state', () async {
      final hasSharedBefore = await repository.hasUserSharedBadge('first_plant', userId: 1);
      expect(hasSharedBefore.dataOrNull, isFalse);

      const badge = BadgeItem(
        id: 'first_plant',
        title: 'Adopsi Pertama',
        desc: 'Desc',
        isUnlocked: true,
        level: 1,
        progress: 1,
        total: 1,
      );

      final post = CommunityPost(
        id: 'badge_share_post',
        authorName: 'User One',
        timeAgo: 'Baru saja',
        category: 'pencapaian',
        content: 'Shared badge',
        attachedBadge: badge,
        userId: 1,
        createdAt: DateTime.now(),
      );
      await repository.createPost(post, userId: 1);

      final hasSharedAfter = await repository.hasUserSharedBadge('first_plant', userId: 1);
      expect(hasSharedAfter.dataOrNull, isTrue);
    });
  });

  group('CommunityRepository SQLite Offline Upload & Sync Tests', () {
    test('createPost saves to SQLite tableCommunityPosts when offline', () async {
      fakeRemote.shouldThrowOnSave = true;

      final offlinePost = CommunityPost(
        id: 'offline_post_1',
        authorName: 'Offline User',
        timeAgo: 'Baru saja',
        category: 'pertanyaan',
        content: 'Post dibuat saat tidak ada internet',
        createdAt: DateTime.now(),
      );

      final result = await repository.createPost(offlinePost, userId: 1);
      expect(result.isSuccess, isTrue);

      // Verify NOT saved to Firebase
      expect(fakeRemote.posts.containsKey('offline_post_1'), isFalse);

      // Verify saved to SQLite tableCommunityPosts as pending upload
      final db = await dbHelper.database;
      final localRows = await db.query(
        DatabaseHelper.tableCommunityPosts,
        where: 'id = ?',
        whereArgs: ['offline_post_1'],
      );
      expect(localRows.length, 1);
      expect(localRows.first['caption'], 'Post dibuat saat tidak ada internet');
    });

    test('getPosts returns offline pending posts when remote fails', () async {
      fakeRemote.shouldThrowOnSave = true;

      final offlinePost = CommunityPost(
        id: 'offline_feed_post',
        authorName: 'Offline User',
        timeAgo: 'Baru saja',
        category: 'tips',
        content: 'Tips offline',
        createdAt: DateTime.now(),
      );
      await repository.createPost(offlinePost, userId: 1);

      // Simulate remote fetch failing due to no internet
      fakeRemote.shouldThrowOnGet = true;

      final postsRes = await repository.getPosts(category: 'tips', currentUserId: 1);
      expect(postsRes.isSuccess, isTrue);
      final posts = postsRes.dataOrNull ?? [];
      expect(posts.length, 1);
      expect(posts.first.id, 'offline_feed_post');
      expect(posts.first.content, 'Tips offline');
    });

    test('syncPendingPosts uploads offline posts to Firebase when internet returns and deletes from SQLite', () async {
      // 1. User creates post while offline
      fakeRemote.shouldThrowOnSave = true;
      final offlinePost = CommunityPost(
        id: 'sync_me_post',
        authorName: 'Offline User',
        timeAgo: 'Baru saja',
        category: 'tips',
        content: 'Unggahan yang menunggu internet kembali',
        createdAt: DateTime.now(),
      );
      await repository.createPost(offlinePost, userId: 1);

      // Verify in SQLite
      final db = await dbHelper.database;
      expect((await db.query(DatabaseHelper.tableCommunityPosts)).length, 1);
      expect(fakeRemote.posts.containsKey('sync_me_post'), isFalse);

      // 2. Internet becomes active again!
      fakeRemote.shouldThrowOnSave = false;
      fakeRemote.shouldThrowOnGet = false;

      // Trigger sync
      await repository.syncPendingPosts();

      // 3. Verify uploaded to Firebase!
      expect(fakeRemote.posts.containsKey('sync_me_post'), isTrue);
      expect(fakeRemote.posts['sync_me_post']?.content,
          'Unggahan yang menunggu internet kembali');

      // 4. Verify DELETED from SQLite pending queue!
      final remainingRows = await db.query(DatabaseHelper.tableCommunityPosts);
      expect(remainingRows.isEmpty, isTrue);
    });

    test('deletePost removes offline pending post before it is uploaded', () async {
      fakeRemote.shouldThrowOnSave = true;
      final offlinePost = CommunityPost(
        id: 'cancel_offline_post',
        authorName: 'User',
        timeAgo: 'Baru saja',
        category: 'pertanyaan',
        content: 'Dibatalkan sebelum internet aktif',
        createdAt: DateTime.now(),
      );
      await repository.createPost(offlinePost, userId: 1);

      final db = await dbHelper.database;
      expect((await db.query(DatabaseHelper.tableCommunityPosts)).length, 1);

      // User deletes the pending post
      final deleteRes = await repository.deletePost('cancel_offline_post', userId: 1);
      expect(deleteRes.isSuccess, isTrue);

      // Verify removed from SQLite
      final remaining = await db.query(DatabaseHelper.tableCommunityPosts);
      expect(remaining.isEmpty, isTrue);
    });
  });
}
