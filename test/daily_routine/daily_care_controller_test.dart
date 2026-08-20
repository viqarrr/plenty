import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/daily_routine/daily_care_controller.dart';
import 'package:plenty/data/datasources/database_helper.dart';
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
  late DailyCareController controller;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final uniqueDbName =
        'daily_care_test_${DateTime.now().microsecondsSinceEpoch}.db';
    dbHelper = DatabaseHelper.forTesting(uniqueDbName);
    await dbHelper.deleteDb();

    final db = await dbHelper.database;
    await db.insert(
      DatabaseHelper.tableUsers,
      {
        'id': 1,
        'email': 'care_user@plenty.app',
        'display_name': 'Care User',
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    plantRepo = PlantRepository(dbHelper: dbHelper);
    careRepo = CareRepository(dbHelper: dbHelper);
    streakRepo = StreakRepository(dbHelper: dbHelper, careRepo: careRepo);

    // Seed test plant
    final addResult = await plantRepo.addPlant(
      userId: '1',
      nickname: 'Monstera Test',
      isIndoor: true,
      initialHeightCm: 42.0,
      defaultWateringInterval: 1,
    );

    // Make watering schedule due today for testing
    await db.update(
      DatabaseHelper.tableCareSchedules,
      {
        'next_due_date':
            DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      },
      where: 'user_plant_id = ? AND task_type = ?',
      whereArgs: [addResult.plant.id, 'siram'],
    );

    controller = DailyCareController(
      plantRepo: plantRepo,
      careRepo: careRepo,
      streakRepo: streakRepo,
    );
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('DailyCareController 2-Layer MVP Tests', () {
    test('Loads today care items with mandatory log and due schedules', () async {
      await controller.loadTodayCare();

      final state = controller.state;
      expect(state.isLoading, isFalse);
      expect(state.heightLogs.isNotEmpty, isTrue);
      expect(state.heightLogs.first.plant.nickname, 'Monstera Test');
      expect(state.heightLogs.first.lastRecordedHeight, 42.0);
      expect(state.heightLogs.first.isCompletedToday, isFalse);

      expect(state.dueSchedules.isNotEmpty, isTrue);
      expect(state.dueSchedules.first.taskType, 'siram');
      expect(state.dueSchedules.first.subtitle, 'Siram 250ml air');
    });

    test('completeHeightTask atomically logs height, adds XP, and updates completed state', () async {
      await controller.loadTodayCare();
      final plant = controller.state.heightLogs.first.plant;

      await controller.completeHeightTask(
        plant: plant,
        heightCm: 43.5,
        note: 'Tunas baru sehat',
      );

      final updatedState = controller.state;
      expect(updatedState.heightLogs.first.isCompletedToday, isTrue);
      expect(updatedState.heightLogs.first.loggedHeightToday, 43.5);

      // Verify care history recorded
      final history = await careRepo.getCareHistory(userId: '1');
      expect(history.any((h) => h.taskType == 'monitor_tinggi'), isTrue);
      expect(history.first.activityDetail, 'Tinggi dicatat: 43.5 cm');
      expect(history.first.xpAwarded, 15);
    });

    test('completeHeightTask with photo atomically saves photo and updates cover', () async {
      await controller.loadTodayCare();
      final plant = controller.state.heightLogs.first.plant;

      // First time with no previous photo -> isPhotoDue should be true
      expect(controller.state.heightLogs.first.isPhotoDue, isTrue);

      await controller.completeHeightTask(
        plant: plant,
        heightCm: 44.0,
        note: 'Foto tunas',
        photoPath: 'assets/images/sample.jpg',
      );

      final updatedState = controller.state;
      expect(updatedState.heightLogs.first.isCompletedToday, isTrue);
      expect(updatedState.heightLogs.first.loggedPhotoPathToday, 'assets/images/sample.jpg');

      final history = await careRepo.getCareHistory(userId: '1');
      expect(history.first.photoPath, 'assets/images/sample.jpg');
    });

    test('updateHeightTask updates growth log, note, and plant height without duplicate XP', () async {
      await controller.loadTodayCare();
      final plant = controller.state.heightLogs.first.plant;

      // 1. Initial completion
      await controller.completeHeightTask(
        plant: plant,
        heightCm: 44.0,
        note: 'Tinggi awal',
      );

      // 2. User edits/updates their log
      await controller.updateHeightTask(
        plant: plant,
        heightCm: 45.5,
        note: 'Revisi setelah diukur ulang',
        photoPath: 'assets/images/revised.jpg',
      );

      final updatedState = controller.state;
      expect(updatedState.heightLogs.first.isCompletedToday, isTrue);
      expect(updatedState.heightLogs.first.loggedHeightToday, 45.5);
      expect(updatedState.heightLogs.first.loggedNoteToday, 'Revisi setelah diukur ulang');
      expect(updatedState.heightLogs.first.loggedPhotoPathToday, 'assets/images/revised.jpg');

      // Verify latest height and photo in care repo
      final latestHeight = await careRepo.getLatestRecordedHeight(plant.id);
      expect(latestHeight, 45.5);
      final latestPhoto = await careRepo.getLoggedPhotoToday(plant.id);
      expect(latestPhoto, 'assets/images/revised.jpg');
    });
  });
}
