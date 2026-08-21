import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/features/forum/data/repositories/forum_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper dbHelper;
  late ForumRepository forumRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper.forTesting('forum_repo_test.db');
    await dbHelper.deleteDb();
    forumRepo = ForumRepository(dbHelper: dbHelper);

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
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('ForumRepository', () {
    test('getPosts auto-seeds default posts and filters by category', () async {
      final allPosts = await forumRepo.getPosts();
      expect(allPosts.isNotEmpty, isTrue);

      final tipsPosts = await forumRepo.getPosts(category: 'Tips & Trik');
      expect(tipsPosts.every((p) => p.category == 'Tips & Trik'), isTrue);
    });

    test('createPost inserts new community post successfully', () async {
      final created = await forumRepo.createPost(
        userId: '1',
        category: 'Tanya Jawab',
        caption: 'Daun monsteraku menguning, kenapa ya?',
      );
      expect(created, isNotNull);
      expect(created.caption, 'Daun monsteraku menguning, kenapa ya?');

      final posts = await forumRepo.getPosts(category: 'Tanya Jawab');
      expect(posts.any((p) => p.id == created.id), isTrue);
    });

    test('toggleKudos updates kudos count', () async {
      final created = await forumRepo.createPost(
        userId: '1',
        category: 'Tips & Trik',
        caption: 'Tips menyiram sukulen',
      );
      expect(created, isNotNull);

      final count1 = await forumRepo.toggleKudos(created.id);
      expect(count1, equals(1));

      final count2 = await forumRepo.toggleKudos(created.id);
      expect(count2, equals(2));
    });

    test('addComment inserts comment and increments post comment_count', () async {
      final post = await forumRepo.createPost(
        userId: '1',
        category: 'Show off',
        caption: 'Lihat monstera baruku!',
      );
      expect(post, isNotNull);

      final comment = await forumRepo.addComment(
        postId: post.id,
        userId: '1',
        content: 'Bagus banget!',
      );
      expect(comment, isNotNull);

      final comments = await forumRepo.getComments(post.id);
      expect(comments.length, equals(1));
      expect(comments.first.content, 'Bagus banget!');
    });
  });
}
