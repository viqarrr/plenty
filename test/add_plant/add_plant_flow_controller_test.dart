import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/data/datasources/database_helper.dart';
import 'package:plenty/data/models/plant_catalog_model.dart';
import 'package:plenty/data/models/time_capsule_model.dart';
import 'package:plenty/data/repositories/plant_repository.dart';
import 'package:plenty/presentation/add_plant/add_plant_flow_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late PlantRepository plantRepo;
  late AddPlantFlowController controller;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final uniqueName =
        'add_plant_test_${DateTime.now().microsecondsSinceEpoch}.db';
    dbHelper = DatabaseHelper.forTesting(uniqueName);
    await dbHelper.deleteDb();

    // Seed default user
    final db = await dbHelper.database;
    await db.insert(DatabaseHelper.tableUsers, {
      'id': 'usr_default',
      'email': 'user@plenty.app',
      'display_name': 'Test User',
      'created_at': DateTime.now().toIso8601String(),
    });

    plantRepo = PlantRepository(dbHelper: dbHelper);
    await plantRepo.getCatalogPlants(); // seeds catalog

    controller = AddPlantFlowController(
      plantRepo: plantRepo,
      entryPoint: AddPlantEntryPoint.onboarding,
      userId: 'usr_default',
    );
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('AddPlantFlowController Unit Tests', () {
    test('Initial state reflects entry point and default values', () {
      expect(controller.state.entryPoint, AddPlantEntryPoint.onboarding);
      expect(controller.state.currentStep, 0);
      expect(controller.state.isIndoor, true);
      expect(controller.state.initialHeightCm, 30.0);
      expect(controller.state.timeCapsuleDraft, isNull);
    });

    test(
      '3-step configuration and confirmAndSave executes atomic insertion',
      () async {
        // Step 1: Select Species
        final species = PlantCatalogModel(
          id: 'cat_monstera',
          commonName: 'Monstera Deliciosa',
          scientificName: 'Monstera deliciosa',
          careLevel: 'EASY CARE',
          defaultWateringInterval: 4,
          cachedAt: DateTime.now(),
        );
        controller.setSpecies(species);
        expect(controller.state.selectedSpecies?.id, 'cat_monstera');
        expect(controller.state.nickname, 'Monstera Deliciosa');
        expect(controller.state.currentStep, 1);

        // Step 2: Set Environment
        controller.setEnvironment(
          isIndoor: true,
          sunlight: 'Sinar Tidak Langsung',
          potSize: 'Ada Lubang Drainase',
          windowDistance: 'Dekat Jendela (1-1.5 meter)',
        );
        expect(controller.state.currentStep, 2);

        // Step 3: Nickname, Height & Time Capsule
        controller.setNicknameAndHeight('Monty The Monster', 35.5);
        expect(controller.state.nickname, 'Monty The Monster');
        expect(controller.state.initialHeightCm, 35.5);

        final capsuleDraft = TimeCapsuleDraft(
          photoPath: 'assets/images/capsule.png',
          note: 'Pesan hari pertama!',
          unlockAt: DateTime.now().add(const Duration(days: 60)),
        );
        controller.setTimeCapsule(capsuleDraft);
        expect(controller.state.timeCapsuleDraft, isNotNull);

        // Save and assert result
        final result = await controller.confirmAndSave();
        expect(result.isFirstPlant, true);
        expect(result.plant.nickname, 'Monty The Monster');
        expect(result.plant.initialHeightCm, 35.5);

        // Verify in DB
        final userPlants = await plantRepo.getUserPlants('usr_default');
        expect(userPlants.length, 1);
        expect(userPlants.first.nickname, 'Monty The Monster');
      },
    );
  });
}
