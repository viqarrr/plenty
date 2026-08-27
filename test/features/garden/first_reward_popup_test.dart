import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/features/garden/data/repositories/growth_repository_impl.dart';
import 'package:plenty/features/garden/domain/models/time_capsule_model.dart';
import 'package:plenty/features/garden/domain/repositories/growth_repository.dart';
import 'package:plenty/features/garden/presentation/widgets/reward_popup.dart';
import 'package:plenty/features/profile/data/repositories/badge_repository_impl.dart';
import 'package:plenty/features/profile/domain/models/badge_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirstRewardPopup / RewardBadgePopup Widget Tests', () {
    testWidgets(
      'FirstRewardPopup.firstPlant renders correctly and responds to dismiss',
      (tester) async {
        bool dismissed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RewardPopup.firstPlant(
                plantNickname: 'Monstera Hijau',
                onDismiss: () => dismissed = true,
              ),
            ),
          ),
        );

        expect(find.text('Badge Pertama Terbuka! 🏆'), findsOneWidget);
        expect(find.textContaining('Monstera Hijau'), findsOneWidget);
        expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
        expect(find.text('Klaim & Lanjutkan'), findsOneWidget);

        await tester.tap(find.text('Klaim & Lanjutkan'));
        await tester.pump();
        expect(dismissed, isTrue);
      },
    );

    testWidgets(
      'FirstRewardPopup.timeCapsule renders correctly for time capsule badge',
      (tester) async {
        bool dismissed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RewardPopup.timeCapsule(
                plantNickname: 'Kaktus Koboi',
                onDismiss: () => dismissed = true,
              ),
            ),
          ),
        );

        expect(find.text('Kapsul Waktu Terbuka! ⏳'), findsOneWidget);
        expect(find.textContaining('Kaktus Koboi'), findsOneWidget);
        expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
        expect(find.text('Klaim & Lanjutkan'), findsOneWidget);

        await tester.tap(find.text('Klaim & Lanjutkan'));
        await tester.pump();
        expect(dismissed, isTrue);
      },
    );

    testWidgets(
      'FirstRewardPopup.fromBadge renders correctly for any generic badge',
      (tester) async {
        bool dismissed = false;
        const testBadge = BadgeItem(
          id: 'water_streak',
          title: 'Penyiram Setia',
          desc: 'Menyiram tanaman tepat waktu selama 7 hari berturut-turut.',
          iconName: 'droplets',
          isUnlocked: true,
          level: 1,
          progress: 7,
          total: 7,
          bgColorHex: '#FBF3DB',
          accentColorHex: '#956400',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RewardPopup.fromBadge(
                badge: testBadge,
                onDismiss: () => dismissed = true,
              ),
            ),
          ),
        );

        expect(find.text('Penyiram Setia Terbuka! 🏆'), findsOneWidget);
        expect(
          find.text(
            'Menyiram tanaman tepat waktu selama 7 hari berturut-turut.',
          ),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.water_drop_rounded), findsOneWidget);

        await tester.tap(find.text('Klaim & Lanjutkan'));
        await tester.pump();
        expect(dismissed, isTrue);
      },
    );
  });

  group('GrowthRepository.saveTimeCapsule Badge Unlocking Unit Tests', () {
    late DatabaseHelper dbHelper;
    late IGrowthRepository growthRepository;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      dbHelper = DatabaseHelper.forTesting('growth_repo_tc_test.db');
      await dbHelper.deleteDb();

      final db = await dbHelper.database;
      await db.insert(DatabaseHelper.tableUsers, {
        'id': 1,
        'email': 'test@plenty.app',
        'display_name': 'Test User',
        'unlocked_badges_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await db.insert(
        DatabaseHelper.tableUserPlants,
        {
          'id': 'plt_test_1',
          'user_id': 1,
          'nickname': 'Calathea',
          'is_indoor': 1,
          'initial_height_cm': 20.0,
          'growth_stage': 'mature',
          'health_status': 'healthy',
          'level': 1,
          'xp': 0,
          'is_archived': 0,
          'adopted_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      growthRepository = GrowthRepositoryImpl(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test(
      'saveTimeCapsule unlocks time_capsule badge on first creation',
      () async {
        final now = DateTime.now();
        final capsule = TimeCapsuleModel(
          id: 'tc_1',
          userPlantId: 'plt_test_1',
          photoPath: 'assets/test.jpg',
          note: 'Pesan rahasia untuk Calathea',
          createdAt: now,
          unlockAt: now.add(const Duration(days: 30)),
          isUnlocked: false,
        );

        final resultRes = await growthRepository.saveTimeCapsule(capsule);
        expect(resultRes.isSuccess, isTrue);
        expect(resultRes.dataOrNull, isTrue); // Newly unlocked

        final badgeRepo = BadgeRepositoryImpl(dbHelper: dbHelper);
        final badgesRes = await badgeRepo.getBadges(userId: 1);
        expect(badgesRes.isSuccess, isTrue);
        final badges = badgesRes.dataOrNull ?? [];
        final tcBadge = badges.firstWhere((b) => b.id == 'time_capsule');
        expect(tcBadge.isUnlocked, isTrue);
        expect(badges.where((b) => b.id == 'time_capsule').length, 1);

        final badgeByIdRes = await badgeRepo.getBadgeById(
          'time_capsule',
          userId: 1,
        );
        expect(badgeByIdRes.isSuccess, isTrue);
        expect(badgeByIdRes.dataOrNull?.isUnlocked, isTrue);

        // Saving a second time capsule should return false (already unlocked)
        final secondCapsule = TimeCapsuleModel(
          id: 'tc_2',
          userPlantId: 'plt_test_1',
          photoPath: 'assets/test2.jpg',
          note: 'Pesan kedua',
          createdAt: now,
          unlockAt: now.add(const Duration(days: 60)),
          isUnlocked: false,
        );
        final secondResultRes = await growthRepository.saveTimeCapsule(
          secondCapsule,
        );
        expect(secondResultRes.isSuccess, isTrue);
        expect(secondResultRes.dataOrNull, isFalse);

        final badgesRes2 = await badgeRepo.getBadges(userId: 1);
        final badges2 = badgesRes2.dataOrNull ?? [];
        expect(badges2.where((b) => b.id == 'time_capsule').length, 1);
        expect(
          badges2.firstWhere((b) => b.id == 'time_capsule').isUnlocked,
          isTrue,
        );
      },
    );
  });
}
