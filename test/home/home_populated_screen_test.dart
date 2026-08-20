import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/daily_routine/daily_care_screen.dart';
import 'package:plenty/data/datasources/database_helper.dart';
import 'package:plenty/data/datasources/preference_handler.dart';
import 'package:plenty/data/repositories/care_repository.dart';
import 'package:plenty/data/repositories/plant_repository.dart';
import 'package:plenty/data/repositories/streak_repository.dart';
import 'package:plenty/presentation/home/home_controller.dart';
import 'package:plenty/presentation/home/home_populated_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late PlantRepository plantRepo;
  late CareRepository careRepo;
  late HomeController controller;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'streak_count': 5,
      'profile_name': 'Nabila',
    });
    await PreferenceHandler.init();

    final uniqueName = 'home_pop_${DateTime.now().microsecondsSinceEpoch}.db';
    dbHelper = DatabaseHelper.forTesting(uniqueName);
    await dbHelper.deleteDb();

    final db = await dbHelper.database;
    await db.insert(
      DatabaseHelper.tableUsers,
      {
        'id': 1,
        'email': 'nabila@plenty.app',
        'display_name': 'Nabila',
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert(
      DatabaseHelper.tableUserStreaks,
      {
        'id': 'streak_1',
        'user_id': 1,
        'current_streak': 5,
        'longest_streak': 5,
        'current_tier': 2,
        'last_streak_date': '2026-08-19',
        'freeze_tokens_available': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    plantRepo = PlantRepository(dbHelper: dbHelper);
    careRepo = CareRepository(dbHelper: dbHelper);
    final streakRepo = StreakRepository(dbHelper: dbHelper, careRepo: careRepo);

    controller = HomeController(
      plantRepo: plantRepo,
      careRepo: careRepo,
      streakRepo: streakRepo,
      userId: '1',
    );
  });

  tearDown(() async {
    await dbHelper.close();
  });

  Widget createTestWidget(HomeController homeController) {
    return ProviderScope(
      overrides: [
        homeControllerProvider.overrideWith((ref) => homeController),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: HomePopulatedScreen(
            onRefresh: () async => homeController.loadDashboard(),
          ),
        ),
      ),
    );
  }

  group('HomePopulatedScreen Dual Card Banner Tests', () {
    testWidgets('Renders Streak Card and Today Tasks Overview Card correctly',
        (tester) async {
      await tester.runAsync(() async {
        await plantRepo.addPlant(
          userId: '1',
          nickname: 'Monstera',
          isIndoor: true,
          initialHeightCm: 30.0,
        );
        await controller.loadDashboard();
      });

      await tester.pumpWidget(createTestWidget(controller));
      await tester.pumpAndSettle();

      // 1. Header greeting (without duplicate badge)
      expect(find.text('Halo, Nabila'), findsOneWidget);
      expect(
        find.text('Waktunya merawat tanamanmu hari ini!'),
        findsOneWidget,
      );
      expect(find.text('5 Hari'), findsNothing);

      // 2. Left Streak Card
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Hari Konsisten'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);

      // 3. Right Tasks Card
      expect(
        find.textContaining('tanaman butuh perhatianmu hari ini'),
        findsOneWidget,
      );
      expect(find.text('Periksa Sekarang'), findsOneWidget);
      expect(find.byIcon(Icons.eco_rounded), findsOneWidget);
    });

    testWidgets('Tapping Periksa Sekarang invokes onNavigateToDailyCare callback when provided',
        (tester) async {
      bool callbackInvoked = false;

      await tester.runAsync(() async {
        await plantRepo.addPlant(
          userId: '1',
          nickname: 'Monstera',
          isIndoor: true,
          initialHeightCm: 30.0,
        );
        await controller.loadDashboard();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeControllerProvider.overrideWith((ref) => controller),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: HomePopulatedScreen(
                onRefresh: () async => controller.loadDashboard(),
                onNavigateToDailyCare: () {
                  callbackInvoked = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Periksa Sekarang'));
      await tester.pump();

      expect(callbackInvoked, isTrue);
    });

    testWidgets('Tapping Periksa Sekarang navigates to DailyCareScreen as fallback when callback is null',
        (tester) async {
      await tester.runAsync(() async {
        await plantRepo.addPlant(
          userId: '1',
          nickname: 'Monstera',
          isIndoor: true,
          initialHeightCm: 30.0,
        );
        await controller.loadDashboard();
      });

      await tester.pumpWidget(createTestWidget(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Periksa Sekarang'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(DailyCareScreen), findsOneWidget);
    });
  });
}
