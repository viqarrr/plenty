import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/daily_care/data/repositories/daily_care_repository_impl.dart';
import 'package:plenty/features/daily_care/domain/repositories/daily_care_repository.dart';
import 'package:plenty/features/daily_care/presentation/controllers/daily_care_controller.dart';
import 'package:plenty/features/garden/data/repositories/plant_repository_impl.dart';
import 'package:plenty/features/garden/domain/models/perenual/plant_catalog_model.dart';
import 'package:plenty/features/garden/domain/repositories/plant_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late IPlantRepository plantRepo;
  late IDailyCareRepository dailyCareRepo;
  late DailyCareController controller;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({'streak_count': 2});
    await PreferenceHandler.init();

    final dbName = 'modular_care_${DateTime.now().microsecondsSinceEpoch}.db';
    dbHelper = DatabaseHelper.forTesting(dbName);
    await dbHelper.deleteDb();

    final db = await dbHelper.database;
    await db.insert(DatabaseHelper.tableUsers, {
      'id': 1,
      'email': 'care_user@plenty.app',
      'username': 'care_user',
      'display_name': 'Care User',
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    plantRepo = PlantRepositoryImpl(dbHelper: dbHelper);
    dailyCareRepo = DailyCareRepositoryImpl(
      dbHelper: dbHelper,
      plantRepo: plantRepo,
    );

    controller = DailyCareController(repository: dailyCareRepo);
  });

  tearDown(() async {
    controller.dispose();
    await dbHelper.close();
  });

  group('Feature-First Daily Care Modular Tests', () {
    test(
      'Initial DailyCareState is loaded with empty plants correctly',
      () async {
        await controller.loadTodayCare();
        expect(controller.state.isLoading, false);
        expect(controller.state.heightLogs, isEmpty);
        expect(controller.state.totalTasksCount, 0);
        expect(controller.state.hasNoTasksScheduled, true);
        expect(controller.state.progressRatio, 0.0);
      },
    );

    test('DailyCareRepository loads plant height and schedule tasks', () async {
      // Add a plant
      final addResultRes = await plantRepo.addPlant(
        userId: '1',
        species: PlantCatalogModel(
          id: 'cat_calathea',
          commonName: 'Calathea Orbifolia',
          defaultWateringInterval: 3,
          cachedAt: DateTime.now(),
        ),
        nickname: 'Calathea Beautiful',
        isIndoor: true,
        initialHeightCm: 20.0,
      );

      final addResult = addResultRes.dataOrNull!;
      expect(addResult, isA<AddPlantResult>());
      expect(addResult.plant.nickname, 'Calathea Beautiful');

      await controller.loadTodayCare();
      expect(controller.state.heightLogs.length, 1);
      expect(
        controller.state.heightLogs.first.plant.nickname,
        'Calathea Beautiful',
      );
      expect(controller.state.heightLogs.first.isCompletedToday, false);
      expect(controller.state.dueSchedules.length, 2);
    });

    test('Completing height task updates state atomically', () async {
      await plantRepo.addPlant(
        userId: '1',
        species: PlantCatalogModel(
          id: 'cat_pothos',
          commonName: 'Golden Pothos',
          defaultWateringInterval: 5,
          cachedAt: DateTime.now(),
        ),
        nickname: 'My Pothos',
        isIndoor: true,
        initialHeightCm: 15.0,
      );

      await controller.loadTodayCare();
      final targetPlant = controller.state.heightLogs.first.plant;

      await controller.completeHeightTask(
        plant: targetPlant,
        heightCm: 16.5,
        note: 'Grew 1.5 cm!',
      );

      expect(controller.state.heightLogs.first.isCompletedToday, true);
      expect(controller.state.heightLogs.first.loggedHeightToday, 16.5);
      expect(controller.state.heightLogs.first.loggedNoteToday, 'Grew 1.5 cm!');
    });

    test('Completing cyclic routine task keeps item in dueSchedules with isCompletedToday: true', () async {
      await plantRepo.addPlant(
        userId: '1',
        species: PlantCatalogModel(
          id: 'cat_monstera',
          commonName: 'Monstera Deliciosa',
          defaultWateringInterval: 7,
          cachedAt: DateTime.now(),
        ),
        nickname: 'My Monstera',
        isIndoor: true,
        initialHeightCm: 30.0,
      );

      await controller.loadTodayCare();
      final targetPlant = controller.state.heightLogs.first.plant;
      expect(controller.state.dueSchedules.length, 2);
      expect(controller.state.dueSchedules.every((s) => !s.isCompletedToday), true);
      expect(controller.state.completedTasksCount, 0);

      await controller.completeRoutineTask(
        plant: targetPlant,
        taskType: 'siram',
      );

      expect(controller.state.dueSchedules.length, 2);
      final siramSchedule = controller.state.dueSchedules.firstWhere(
        (s) => s.taskType == 'siram',
      );
      expect(siramSchedule.isCompletedToday, true);
      expect(controller.state.completedTasksCount, 1);
    });

    test('Plant without schedules auto-repairs and displays in dueSchedules', () async {
      final db = await dbHelper.database;
      await db.insert(DatabaseHelper.tableUserPlants, {
        'id': 'orphan_plant_1',
        'user_id': 1,
        'nickname': 'Orphan Plant',
        'initial_height_cm': 20.0,
        'current_height': 20.0,
        'default_watering_interval': 3,
        'is_archived': 0,
        'adopted_at': DateTime.now().toIso8601String(),
      });

      final taskTypesRes = await dailyCareRepo.getTodaysTaskTypes('orphan_plant_1');
      final taskTypes = taskTypesRes.dataOrNull!;
      expect(taskTypes.contains('siram'), true);
      expect(taskTypes.contains('bersih'), true);

      final stateRes = await dailyCareRepo.loadDailyCareData();
      final state = stateRes.dataOrNull!;
      expect(state.dueSchedules.any((s) => s.plant.id == 'orphan_plant_1' && s.taskType == 'siram'), true);
      expect(state.dueSchedules.any((s) => s.plant.id == 'orphan_plant_1' && s.taskType == 'bersih'), true);
    });

    test('Completed task persists and never reverts to uncompleted on subsequent loads', () async {
      await plantRepo.addPlant(
        userId: '1',
        species: PlantCatalogModel(
          id: 'cat_sansevieria',
          commonName: 'Snake Plant',
          defaultWateringInterval: 14,
          cachedAt: DateTime.now(),
        ),
        nickname: 'My Sansevieria',
        isIndoor: true,
        initialHeightCm: 25.0,
      );

      await controller.loadTodayCare();
      final targetPlant = controller.state.heightLogs.first.plant;

      await controller.completeRoutineTask(
        plant: targetPlant,
        taskType: 'siram',
      );

      // Verify it is completed
      var siramSchedule = controller.state.dueSchedules.firstWhere(
        (s) => s.plant.id == targetPlant.id && s.taskType == 'siram',
      );
      expect(siramSchedule.isCompletedToday, true);

      // Re-load care data multiple times (simulating pull-to-refresh or tab switching)
      await controller.loadTodayCare();
      siramSchedule = controller.state.dueSchedules.firstWhere(
        (s) => s.plant.id == targetPlant.id && s.taskType == 'siram',
      );
      expect(siramSchedule.isCompletedToday, true);

      await controller.loadTodayCare(silent: true);
      siramSchedule = controller.state.dueSchedules.firstWhere(
        (s) => s.plant.id == targetPlant.id && s.taskType == 'siram',
      );
      expect(siramSchedule.isCompletedToday, true);
    });
  });
}
