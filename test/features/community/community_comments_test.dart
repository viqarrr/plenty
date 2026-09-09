import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/di/injector.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/community/data/repositories/community_repository_impl.dart';
import 'package:plenty/features/community/domain/models/community_post.dart';
import 'package:plenty/features/community/domain/repositories/community_repository.dart';
import 'package:plenty/features/community/presentation/controllers/community_controller.dart';
import 'package:plenty/features/community/presentation/widgets/community_post_card.dart';
import 'package:plenty/features/community/presentation/widgets/post_comments_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late ICommunityRepository repository;
  late CommunityController controller;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferenceHandler.init();

    dbHelper = DatabaseHelper.forTesting(
      'community_comments_test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    final db = await dbHelper.database;
    await db.insert(
      DatabaseHelper.tableUsers,
      {
        'id': 1,
        'email': 'tester@plenty.app',
        'username': 'tester_plenty',
        'display_name': 'Tester Plenty',
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    repository = CommunityRepositoryImpl(dbHelper: dbHelper);
    await repository.seedInitialPosts();
    Injector.databaseHelper = dbHelper;
    Injector.communityRepository = repository;
    controller = CommunityController(repository: repository);
    await controller.loadPosts();
  });

  tearDown(() async {
    Injector.reset();
    await dbHelper.close();
  });

  final testPost = CommunityPost(
    id: 'post_comm_1',
    authorName: 'Botanist',
    timeAgo: 'Baru saja',
    category: 'pertanyaan',
    content: 'Apakah monstera aman untuk kucing?',
    likesCount: 0,
    commentsCount: 0,
    createdAt: DateTime.now(),
  );

  group('CommunityController Comment Methods', () {
    test('addComment increments commentsCount in controller posts', () async {
      await repository.createPost(testPost, userId: 1);
      await controller.loadPosts();

      final created = await controller.addComment(
        'post_comm_1',
        'Monstera beracun bagi kucing karena mengandung kalsium oksalat!',
      );
      expect(created, isNotNull);
      expect(created!.content, contains('Monstera beracun'));

      final updatedPost = controller.posts.firstWhere((p) => p.id == 'post_comm_1');
      expect(updatedPost.commentsCount, 1);

      final comments = await controller.getComments('post_comm_1');
      expect(comments.length, 1);
      expect(comments.first.content, contains('Monstera beracun'));

      // Now delete
      final deleteSuccess = await controller.deleteComment(
        'post_comm_1',
        created.id,
      );
      expect(deleteSuccess, isTrue);

      final postAfterDelete = controller.posts.firstWhere((p) => p.id == 'post_comm_1');
      expect(postAfterDelete.commentsCount, 0);
    });
  });

  group('PostCommentsSheet UI Tests', () {
    testWidgets('Renders empty state when post has no comments', (tester) async {
      await tester.runAsync(() async {
        await repository.createPost(testPost, userId: 1);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostCommentsSheet(
              controller: controller,
              post: testPost,
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(find.text('Komentar'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Belum Ada Komentar'), findsOneWidget);
      expect(
        find.text('Jadilah yang pertama berkomentar di diskusi ini!'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Renders existing comments with author and content', (tester) async {
      await tester.runAsync(() async {
        await repository.createPost(testPost, userId: 1);
        await repository.addComment(
          postId: testPost.id,
          content: 'Perhatikan drainase pot agar tidak busuk akar.',
          userId: 1,
          authorName: 'Alex Green',
        );
        await controller.loadPosts();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostCommentsSheet(
              controller: controller,
              post: testPost,
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pump();

      expect(find.text('Komentar'), findsOneWidget);
      expect(find.text('1'), findsWidgets);
      expect(find.text('tester_plenty'), findsOneWidget);
      expect(
        find.text('Perhatikan drainase pot agar tidak busuk akar.'),
        findsOneWidget,
      );
    });

    testWidgets('CommunityPostCard comment button triggers onCommentTap callback', (
      tester,
    ) async {
      bool commentTapped = false;
      final post = testPost.copyWith(commentsCount: 3);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommunityPostCard(
              post: post,
              onCommentTap: () => commentTapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded));
      await tester.pump();

      expect(commentTapped, isTrue);
    });
  });
}
