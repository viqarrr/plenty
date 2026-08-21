import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/plant_catalog/domain/models/plant_catalog_model.dart';
import 'package:plenty/features/garden/data/repositories/plant_repository.dart';
import 'package:plenty/features/daily_care/data/daily_care_repository.dart';
import 'package:plenty/features/daily_care/presentation/daily_care_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late PlantRepository plantRepo;
  late DailyCareRepository dailyCareRepo;
  late DailyCareController controller;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'streak_count': 2,
    });
    await PreferenceHandler.init();

    final dbName = 'modular_care_${DateTime.now().microsecondsSinceEpoch}.db';
    dbHelper = DatabaseHelper.forTesting(dbName);
    await dbHelper.deleteDb();

    final db = await dbHelper.database;
    await db.insert(
      DatabaseHelper.tableUsers,
      {
        'id': 1,
        'email': 'care_user@plenty.app',
        'username': 'care_user',
        'display_name': 'Care User',
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    plantRepo = PlantRepository(dbHelper: dbHelper);
    dailyCareRepo = DailyCareRepository(
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
    test('Initial DailyCareState is loaded with empty plants correctly', () async {
      await controller.loadTodayCare();
      expect(controller.state.isLoading, false);
      expect(controller.state.heightLogs, isEmpty);
      expect(controller.state.totalTasksCount, 0);
      expect(controller.state.hasNoTasksScheduled, true);
      expect(controller.state.progressRatio, 0.0);
    });

    test('DailyCareRepository loads plant height and schedule tasks', () async {
      // Add a plant
      final addResult = await plantRepo.addPlant(
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

      expect(addResult, isA<AddPlantResult>());
      expect(addResult.plant.nickname, 'Calathea Beautiful');

      await controller.loadTodayCare();
      expect(controller.state.heightLogs.length, 1);
      expect(controller.state.heightLogs.first.plant.nickname, 'Calathea Beautiful');
      expect(controller.state.heightLogs.first.isCompletedToday, false);
      expect(controller.state.dueSchedules, isEmpty);
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
  });
}
