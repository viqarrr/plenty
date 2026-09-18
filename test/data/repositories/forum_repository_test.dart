import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/features/community/data/repositories/community_repository_impl.dart';
import 'package:plenty/features/community/domain/models/community_post.dart';
import 'package:plenty/features/community/domain/repositories/community_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../features/community/fake_community_remote_datasource.dart';

void main() {
  late DatabaseHelper dbHelper;
  late FakeCommunityRemoteDataSource fakeRemote;
  late ICommunityRepository communityRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper.forTesting('community_repo_suite_test.db');
    await dbHelper.deleteDb();
    fakeRemote = FakeCommunityRemoteDataSource();
    communityRepo = CommunityRepositoryImpl(
      dbHelper: dbHelper,
      remoteDataSource: fakeRemote,
    );

    final db = await dbHelper.database;
    await db.insert(
      DatabaseHelper.tableUsers,
      {
        'id': 1,
        'email': 'test@plenty.app',
        'display_name': 'Test User',
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Initial remote posts
    await fakeRemote.savePost(CommunityPost(
      id: 'init_p1',
      authorName: 'Alex',
      timeAgo: 'Baru saja',
      category: 'tips',
      content: 'Tips rawat monstera',
      createdAt: DateTime.now(),
    ));
    await fakeRemote.savePost(CommunityPost(
      id: 'init_p2',
      authorName: 'Rian',
      timeAgo: 'Baru saja',
      category: 'pertanyaan',
      content: 'Tanya pupuk organik',
      createdAt: DateTime.now(),
    ));
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('CommunityRepository Suite Tests', () {
    test('getPosts returns posts and filters by category', () async {
      final allPostsRes = await communityRepo.getPosts();
      final allPosts = allPostsRes.dataOrNull ?? [];
      expect(allPosts.isNotEmpty, isTrue);

      final tipsPostsRes = await communityRepo.getPosts(category: 'tips');
      final tipsPosts = tipsPostsRes.dataOrNull ?? [];
      expect(tipsPosts.every((p) => p.category == 'tips'), isTrue);
    });

    test('createPost inserts new community post successfully', () async {
      final newPost = CommunityPost(
        id: 'cp_test_1',
        authorName: 'Botanist User',
        timeAgo: 'Baru saja',
        category: 'pertanyaan',
        content: 'Daun monsteraku menguning, kenapa ya?',
        createdAt: DateTime.now(),
      );

      final createdRes = await communityRepo.createPost(newPost, userId: 1);
      final created = createdRes.dataOrNull;
      expect(created?.id, 'cp_test_1');

      final postsRes = await communityRepo.getPosts(category: 'pertanyaan');
      final posts = postsRes.dataOrNull ?? [];
      expect(posts.any((p) => p.id == 'cp_test_1'), isTrue);
    });

    test('toggleLike updates like status and count', () async {
      final newPost = CommunityPost(
        id: 'cp_test_2',
        authorName: 'Botanist User',
        timeAgo: 'Baru saja',
        category: 'tips',
        content: 'Tips menyiram sukulen',
        createdAt: DateTime.now(),
      );

      await communityRepo.createPost(newPost, userId: 1);

      final likedRes = await communityRepo.toggleLike('cp_test_2', userId: 1);
      final liked = likedRes.dataOrNull;
      expect(liked?.isLiked, isTrue);
      expect(liked?.likesCount, 1);

      final unlikedRes = await communityRepo.toggleLike('cp_test_2', userId: 1);
      final unliked = unlikedRes.dataOrNull;
      expect(unliked?.isLiked, isFalse);
      expect(unliked?.likesCount, 0);
    });
  });
}
