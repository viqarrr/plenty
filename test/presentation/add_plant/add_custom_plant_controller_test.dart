import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/features/garden/data/repositories/plant_repository.dart';
import 'package:plenty/features/plant_catalog/presentation/controllers/add_custom_plant_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late PlantRepository plantRepository;
  late AddCustomPlantController controller;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper.forTesting('custom_plant_test.db');
    await dbHelper.deleteDb();

    // Seed test user
    final db = await dbHelper.database;
    await db.insert(
      DatabaseHelper.tableUsers,
      {
        'id': 1,
        'email': 'user@plenty.app',
        'display_name': 'Plant Lover',
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    plantRepository = PlantRepository(dbHelper: dbHelper);
    controller = AddCustomPlantController(plantRepo: plantRepository, userId: '1');
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('AddCustomPlantController Unit Tests', () {
    test('Initial state starts at step 0 and requires plant name', () {
      expect(controller.state.currentStep, 0);
      expect(controller.state.plantName, '');
      expect(controller.state.isCurrentStepValid, false);
    });

    test('Validates plant name before advancing to step 1', () {
      controller.setPlantName('Bonsai Beringin');
      expect(controller.state.isCurrentStepValid, true);

      controller.nextStep();
      expect(controller.state.currentStep, 1);
    });

    test('Transitions through all 5 steps smoothly', () {
      controller.setPlantName('Aglaonema');
      controller.nextStep(); // Step 1: Environment & Drainage
      expect(controller.state.currentStep, 1);

      controller.setEnvironment('Indoor');
      controller.setDrainage('Ada Lubang Drainase');
      controller.nextStep(); // Step 2: Room
      expect(controller.state.currentStep, 2);

      controller.setRoom('Kamar Tidur');
      controller.nextStep(); // Step 3: Light
      expect(controller.state.currentStep, 3);

      controller.setLight('Teduh Sebagian (Partial Shade)');
      controller.nextStep(); // Step 4: Time Capsule
      expect(controller.state.currentStep, 4);
    });

    test('Submitting custom plant successfully saves to database', () async {
      controller.setPlantName('Kaktus Mini');
      controller.setEnvironment('Indoor');
      controller.setDrainage('Ada Lubang Drainase');
      controller.setRoom('Meja Kerja');
      controller.setLight('Sinar Tidak Langsung Terang');

      final success = await controller.submitCustomPlant();
      expect(success, true);
      expect(controller.state.isSuccess, true);

      // Verify saved in SQLite
      final plants = await plantRepository.getUserPlants('1');
      expect(plants.length, 1);
      expect(plants.first.nickname, 'Kaktus Mini');
      expect(plants.first.isIndoor, true);
      expect(plants.first.potSize, 'Ada Lubang Drainase');
    });
  });
}
