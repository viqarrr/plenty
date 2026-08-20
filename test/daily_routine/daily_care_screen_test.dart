import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/daily_routine/care_history_screen.dart';
import 'package:plenty/daily_routine/daily_care_controller.dart';
import 'package:plenty/daily_routine/daily_care_screen.dart';
import 'package:plenty/daily_routine/monitor_tinggi_input_sheet.dart';
import 'package:plenty/data/datasources/database_helper.dart';
import 'package:plenty/data/models/plant_model.dart';
import 'package:plenty/data/repositories/care_repository.dart';
import 'package:plenty/data/repositories/plant_repository.dart';
import 'package:plenty/data/repositories/streak_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late PlantRepository plantRepo;
  late CareRepository careRepo;
  late StreakRepository streakRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final uniqueDbName =
        'daily_screen_test_${DateTime.now().microsecondsSinceEpoch}.db';
    dbHelper = DatabaseHelper.forTesting(uniqueDbName);
    await dbHelper.deleteDb();

    final db = await dbHelper.database;
    await db.insert(
      DatabaseHelper.tableUsers,
      {
        'id': 1,
        'email': 'care_screen@plenty.app',
        'display_name': 'Care Screen User',
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    plantRepo = PlantRepository(dbHelper: dbHelper);
    careRepo = CareRepository(dbHelper: dbHelper);
    streakRepo = StreakRepository(dbHelper: dbHelper, careRepo: careRepo);

    final plant = PlantModel(
      id: 'plt_fiddle_1',
      userId: '1',
      nickname: 'Fiddle Leaf',
      isIndoor: true,
      initialHeightCm: 45.0,
      adoptedAt: DateTime.now(),
    );
    await db.insert(DatabaseHelper.tableUserPlants, plant.toMap());
    await db.insert(
      DatabaseHelper.tableCareSchedules,
      {
        'id': 'sched_fiddle_siram',
        'user_plant_id': plant.id,
        'task_type': 'siram',
        'interval_days': 1,
        'next_due_date':
            DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'is_active': 1,
      },
    );
  });

  tearDown(() async {
    await dbHelper.close();
  });

  Widget createTestWidget(DailyCareController controller) {
    return ProviderScope(
      overrides: [
        careRepositoryProvider.overrideWithValue(careRepo),
        dailyCareControllerProvider.overrideWith((ref) => controller),
      ],
      child: const MaterialApp(
        home: DailyCareScreen(),
      ),
    );
  }

  group('DailyCareScreen Widget Tests', () {
    testWidgets('Renders header, streak badge, Mandatory Log, and Due Schedules',
        (tester) async {
      late final DailyCareController controller;
      await tester.runAsync(() async {
        controller = DailyCareController(
          plantRepo: plantRepo,
          careRepo: careRepo,
          streakRepo: streakRepo,
        );
        await controller.loadTodayCare();
      });

      await tester.pumpWidget(createTestWidget(controller));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(find.text('Tugas Hari Ini'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);

      expect(find.text('Log Pertumbuhan Harian'), findsOneWidget);
      expect(find.text('Fiddle Leaf'), findsWidgets);
      expect(find.text('Tinggi terakhir: 45.0 cm'), findsOneWidget);
      expect(find.text('Catat cm'), findsOneWidget);

      expect(find.text('Jadwal Rutin'), findsOneWidget);
    });

    testWidgets('Tapping Catat cm opens MonitorTinggiInputSheet', (tester) async {
      late final DailyCareController controller;
      await tester.runAsync(() async {
        controller = DailyCareController(
          plantRepo: plantRepo,
          careRepo: careRepo,
          streakRepo: streakRepo,
        );
        await controller.loadTodayCare();
      });

      await tester.pumpWidget(createTestWidget(controller));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      await tester.tap(find.text('Catat cm'));
      await tester.pumpAndSettle();

      expect(find.byType(MonitorTinggiInputSheet), findsOneWidget);
      expect(find.text('Simpan Perkembangan (+15 XP)'), findsOneWidget);
    });

    testWidgets('Tapping History icon opens CareHistoryScreen', (tester) async {
      late final DailyCareController controller;
      await tester.runAsync(() async {
        controller = DailyCareController(
          plantRepo: plantRepo,
          careRepo: careRepo,
          streakRepo: streakRepo,
        );
        await controller.loadTodayCare();
      });

      await tester.pumpWidget(createTestWidget(controller));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      await tester.tap(find.byIcon(Icons.history));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CareHistoryScreen), findsOneWidget);
      expect(find.text('Riwayat Perawatan'), findsOneWidget);
    });

    testWidgets('Completed height log shows check icon and edit icon, opens edit sheet on tap', (tester) async {
      late final DailyCareController controller;
      await tester.runAsync(() async {
        controller = DailyCareController(
          plantRepo: plantRepo,
          careRepo: careRepo,
          streakRepo: streakRepo,
        );
        await controller.loadTodayCare();
        final plant = controller.state.heightLogs.first.plant;
        await controller.completeHeightTask(
          plant: plant,
          heightCm: 45.0,
          note: 'Catatan pagi',
        );
      });

      await tester.pumpWidget(createTestWidget(controller));
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(MonitorTinggiInputSheet), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);
    });
  });
}
