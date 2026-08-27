import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/di/injector.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/community/data/repositories/community_repository_impl.dart';
import 'package:plenty/features/community/domain/models/community_post.dart';
import 'package:plenty/features/community/domain/repositories/community_repository.dart';
import 'package:plenty/features/community/presentation/controllers/community_controller.dart';
import 'package:plenty/features/community/presentation/screens/community_screen.dart';
import 'package:plenty/features/community/presentation/screens/create_post_screen.dart';
import 'package:plenty/features/community/presentation/widgets/community_post_card.dart';
import 'package:plenty/features/profile/domain/models/badge_item.dart';
import 'package:plenty/features/profile/presentation/screens/badge_detail_screen.dart';
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
      'community_widgets_test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    final db = await dbHelper.database;
    await db.insert(DatabaseHelper.tableUsers, {
      'id': 1,
      'email': 'alex@gardner.com',
      'username': 'alex_plants',
      'display_name': 'Alex Gardner',
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    repository = CommunityRepositoryImpl(dbHelper: dbHelper);
    await repository.seedInitialPosts();
    Injector.databaseHelper = dbHelper;
    Injector.communityRepository = repository;
    controller = CommunityController(repository: repository);
  });

  tearDown(() async {
    Injector.reset();
    await dbHelper.close();
  });

  const sampleBadge = BadgeItem(
    id: 'first_plant',
    title: 'Adopsi Pertama',
    desc: 'Mengadopsi tanaman pertama untuk memulai perjalanan berkebunmu.',
    iconName: 'eco',
    isUnlocked: true,
    unlockedDate: '23 Ags 2026',
    level: 1,
    progress: 1,
    total: 1,
    bgColorHex: '#EBF7F1',
    accentColorHex: '#2D6A4F',
  );

  final samplePosts = [
    CommunityPost(
      id: 'p_1',
      authorName: 'Sarah Gardener',
      timeAgo: '10m lalu',
      category: 'pertanyaan',
      content: 'Berapa frekuensi siram monstera yang ideal di musim hujan?',
      likesCount: 0,
      isLiked: false,
      isAuthor: false,
      commentsCount: 2,
      createdAt: DateTime.now(),
    ),
    CommunityPost(
      id: 'p_2',
      authorName: 'Alex Green',
      timeAgo: '1j lalu',
      category: 'pencapaian',
      content: 'Hore! Membuka lencana Adopsi Pertama di Plenty! 🌱',
      attachedBadge: sampleBadge,
      likesCount: 8,
      isLiked: true,
      isAuthor: true,
      commentsCount: 1,
      createdAt: DateTime.now(),
    ),
  ];

  group('CommunityPostCard Widget Tests', () {
    testWidgets(
      'Renders author, category pill, content, and attached badge card',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: CommunityPostCard(post: samplePosts[1])),
          ),
        );

        expect(find.text('Alex Green'), findsOneWidget);
        expect(find.text('Pencapaian'), findsOneWidget);
        expect(
          find.text('Hore! Membuka lencana Adopsi Pertama di Plenty! 🌱'),
          findsOneWidget,
        );
        expect(find.text('Pencapaian Terbuka! 🏆'), findsOneWidget);
        expect(find.text('Adopsi Pertama'), findsOneWidget);
        expect(find.text('8'), findsOneWidget);
      },
    );

    testWidgets('Hides popup menu when post.isAuthor is false', (tester) async {
      final otherUserPost = CommunityPost(
        id: 'other_post',
        authorName: 'Other Person',
        timeAgo: '5m lalu',
        category: 'tips',
        content: 'Tips dari orang lain',
        isAuthor: false,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommunityPostCard(
              post: otherUserPost,
              onEditTap: () {},
              onDeleteTap: () {},
            ),
          ),
        ),
      );

      // Popup menu button with 3 dots should NOT be rendered for another user's post
      expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
    });
  });

  group('CommunityScreen Widget Tests', () {
    testWidgets('Renders header bar, category filters, and FAB', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await controller.loadPosts();
      });
      await tester.pumpWidget(
        MaterialApp(home: CommunityScreen(controller: controller)),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(find.text('Komunitas'), findsOneWidget);
      expect(find.text('Temukan & Berbagi Tips Tanaman'), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Tips & Trick'), findsWidgets);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Tapping category filter updates active category', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await controller.loadPosts();
      });
      await tester.pumpWidget(
        MaterialApp(home: CommunityScreen(controller: controller)),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      await tester.runAsync(() async {
        await controller.setCategory('pencapaian');
      });
      await tester.pump();

      expect(controller.selectedCategory, 'pencapaian');
    });

    testWidgets('Tapping FAB opens CreatePostScreen', (tester) async {
      await tester.runAsync(() async {
        await controller.loadPosts();
      });
      await tester.pumpWidget(
        MaterialApp(home: CommunityScreen(controller: controller)),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CreatePostScreen), findsOneWidget);
      expect(find.text('Buat Postingan'), findsOneWidget);
      expect(find.text('PILIH KATEGORI'), findsOneWidget);
    });
  });

  group('CreatePostScreen Widget Tests', () {
    testWidgets('Allows choosing Pertanyaan vs Tips & validates empty text', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<bool>(
                    builder: (_) => CreatePostScreen(controller: controller),
                  ),
                ),
                child: const Text('Open Create Post'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Create Post'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pertanyaan'), findsOneWidget);
      expect(find.text('Tips & Trick'), findsOneWidget);

      // Select Tips & Trick
      await tester.tap(find.text('Tips & Trick'));
      await tester.pump();

      // Tap Posting without input
      await tester.tap(find.text('Posting'));
      await tester.pump();

      expect(find.text('Silakan tulis konten postingan Anda'), findsWidgets);
    });
  });

  group('Share Badge Integration in BadgeDetailScreen', () {
    testWidgets(
      'BadgeDetailScreen renders "Bagikan ke Komunitas" button when unlocked and not yet shared',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: BadgeDetailScreen(badge: sampleBadge, isAlreadyShared: false),
          ),
        );
        await tester.pump();

        expect(find.byType(BadgeDetailScreen), findsOneWidget);
        expect(find.text('Bagikan ke Komunitas'), findsOneWidget);
      },
    );

    test(
      'CommunityRepository enforces single badge share and duplicate prevention',
      () async {
        // First share succeeds
        final firstShareRes = await repository.createPost(
          CommunityPost(
            id: 'first_badge_share',
            authorName: 'Alex Gardner',
            timeAgo: 'Baru saja',
            category: 'pencapaian',
            content: 'First share of badge',
            attachedBadge: sampleBadge,
            createdAt: DateTime.now(),
          ),
          userId: 1,
        );
        expect(firstShareRes.isSuccess, isTrue);

        // Verify repository marks badge as shared
        final hasSharedRes = await repository.hasUserSharedBadge(
          sampleBadge.id,
          userId: 1,
        );
        expect(hasSharedRes.dataOrNull, isTrue);

        // Duplicate share of same badge is rejected
        final duplicateShareRes = await repository.createPost(
          CommunityPost(
            id: 'duplicate_post',
            authorName: 'Alex Gardner',
            timeAgo: 'Baru saja',
            category: 'pencapaian',
            content: 'Duplicate share test',
            attachedBadge: sampleBadge,
            createdAt: DateTime.now(),
          ),
          userId: 1,
        );
        expect(duplicateShareRes.isError, isTrue);
        expect(
          duplicateShareRes.failureOrNull?.message,
          contains('sudah pernah Anda bagikan'),
        );
      },
    );

    testWidgets(
      'BadgeDetailScreen displays disabled "Sudah Dibagikan ke Komunitas" when badge has been shared',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: BadgeDetailScreen(badge: sampleBadge, isAlreadyShared: true),
          ),
        );
        await tester.pump();

        expect(find.text('Sudah Dibagikan ke Komunitas'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
        expect(find.byType(ElevatedButton), findsNothing);
      },
    );
  });

  group('Edit and Delete Community Post Widget Tests', () {
    testWidgets(
      'CreatePostScreen pre-fills content and updates post when editing',
      (tester) async {
        final postToEdit = CommunityPost(
          id: 'post_to_edit',
          authorName: 'Alex Green',
          timeAgo: '1j lalu',
          category: 'pertanyaan',
          content: 'Konten lama sebelum diedit',
          isAuthor: true,
          createdAt: DateTime.now(),
        );

        await tester.runAsync(() async {
          await repository.createPost(postToEdit, userId: 1);
          await controller.loadPosts();
        });

        await tester.pumpWidget(
          MaterialApp(
            home: CreatePostScreen(
              controller: controller,
              initialPost: postToEdit,
            ),
          ),
        );

        expect(find.text('Edit Postingan'), findsOneWidget);
        expect(find.text('Simpan'), findsOneWidget);
        expect(find.text('Konten lama sebelum diedit'), findsOneWidget);

        await tester.enterText(
          find.byType(TextField),
          'Konten sudah diperbarui dengan baik!',
        );
        await tester.pump();

        await tester.runAsync(() async {
          await tester.tap(find.text('Simpan'));
          await Future<void>.delayed(const Duration(milliseconds: 500));
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final updatedPosts = controller.posts;
        expect(
          updatedPosts.any(
            (p) => p.content == 'Konten sudah diperbarui dengan baik!',
          ),
          isTrue,
        );
      },
    );

    testWidgets(
      'CommunityPostCard popup menu triggers onEditTap and onDeleteTap for author',
      (tester) async {
        bool editCalled = false;
        bool deleteCalled = false;

        final post = CommunityPost(
          id: 'post_card_test',
          authorName: 'Alex Green',
          timeAgo: '1j lalu',
          category: 'tips',
          content: 'Postingan testing menu',
          isAuthor: true,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommunityPostCard(
                post: post,
                onEditTap: () => editCalled = true,
                onDeleteTap: () => deleteCalled = true,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
        await tester.tap(find.byIcon(Icons.more_horiz_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Edit Postingan'), findsOneWidget);
        expect(find.text('Hapus Postingan'), findsOneWidget);

        await tester.tap(find.text('Hapus Postingan'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(deleteCalled, isTrue);
        expect(editCalled, isFalse);
      },
    );

    test('CommunityController deletePost removes post correctly', () async {
      final postToDelete = CommunityPost(
        id: 'post_to_delete',
        authorName: 'Alex Green',
        timeAgo: '1j lalu',
        category: 'tips',
        content: 'Postingan untuk dihapus',
        isAuthor: true,
        createdAt: DateTime.now(),
      );

      await repository.createPost(postToDelete, userId: 1);
      await controller.loadPosts();
      expect(controller.posts.any((p) => p.id == 'post_to_delete'), isTrue);

      final success = await controller.deletePost('post_to_delete');
      expect(success, isTrue);
      expect(controller.posts.any((p) => p.id == 'post_to_delete'), isFalse);
    });
  });
}
