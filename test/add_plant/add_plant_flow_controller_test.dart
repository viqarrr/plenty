import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/data/datasources/database_helper.dart';
import 'package:plenty/data/models/plant_catalog_model.dart';
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

    // Seed default user (or rely on _onCreate user 1)
    final db = await dbHelper.database;
    await db.insert(
      DatabaseHelper.tableUsers,
      {
        'id': 1,
        'email': 'user@plenty.app',
        'display_name': 'Test User',
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    plantRepo = PlantRepository(dbHelper: dbHelper);
    await plantRepo.getCatalogPlants(); // seeds catalog

    controller = AddPlantFlowController(
      plantRepo: plantRepo,
      entryPoint: AddPlantEntryPoint.onboarding,
      userId: '1',
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
      expect(controller.state.environment, 'Indoor');
      expect(controller.state.potSize, 'Ada Lubang Drainase');
      expect(controller.state.timeCapsuleDraft, isNull);
    });

    test(
      'Custom Wizard adoption flow and confirmAndSave executes atomic insertion',
      () async {
        // Step 0 -> Step 1: Select Species -> Previews Details
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
        expect(controller.state.plantName, 'Monstera Deliciosa');
        expect(controller.state.currentStep, 1);

        // Step 1 -> Step 2: User clicks "Tambahkan ke Koleksi" CTA
        controller.proceedFromPreviewToWizard();
        expect(controller.state.currentStep, 2);
        expect(controller.state.wizardStepIndex, 0); // Wizard Step 1: Name & Photo

        // Step 2: Custom Name & Photo
        controller.setPlantName('Monty The Monster');
        controller.nextStep();
        expect(controller.state.currentStep, 3);
        expect(controller.state.wizardStepIndex, 1); // Wizard Step 2: Growth Stage (Asal Pertumbuhan)

        // Step 3: Growth Stage (Dari Bibit vs Sudah Tumbuh)
        controller.setGrowthStage('seed');
        expect(controller.state.growthStage, 'seed');
        expect(controller.state.initialHeightCm, 2.0); // automatically set to seedling height
        controller.nextStep();
        expect(controller.state.currentStep, 4);
        expect(controller.state.wizardStepIndex, 2); // Wizard Step 3: Environment & Drainage

        // Step 4: Environment (Indoor vs Outdoor) & Drainage
        controller.setEnvironment('Indoor');
        controller.setDrainage('Ada Lubang Drainase');
        controller.nextStep();
        expect(controller.state.currentStep, 5);
        expect(controller.state.wizardStepIndex, 3); // Wizard Step 4: Room / Area

        // Step 5: Area / Room
        controller.setRoom('Ruang Tamu');
        controller.nextStep();
        expect(controller.state.currentStep, 6);
        expect(controller.state.wizardStepIndex, 4); // Wizard Step 5: Light Conditions

        // Step 6: Light Conditions
        controller.setLight('Sinar Tidak Langsung Terang');
        controller.nextStep();
        expect(controller.state.currentStep, 7);
        expect(controller.state.wizardStepIndex, 5); // Wizard Step 6: Time Capsule

        // Step 7: Time Capsule & Date
        controller.toggleTimeCapsule(true);
        controller.setTimeCapsuleMessage('Pesan kapsul waktu hari pertama!');
        expect(controller.state.timeCapsuleDraft, isNotNull);

        // Final Action: confirmAndSave
        final result = await controller.confirmAndSave();
        expect(result.plant.nickname, 'Monty The Monster');
        expect(result.plant.catalogId, 'cat_monstera');
        expect(result.plant.growthStage, 'seed');
        expect(result.plant.isFromSeed, true);
        expect(result.plant.growthStageLabel, 'Dari Bibit');
        expect(result.isFirstPlant, true);

        // Verify SQLite user_plants
        final userPlants = await plantRepo.getUserPlants('1');
        expect(userPlants.length, 1);
        expect(userPlants.first.nickname, 'Monty The Monster');
        expect(userPlants.first.catalogId, 'cat_monstera');
        expect(userPlants.first.growthStage, 'seed');
        expect(userPlants.first.isFromSeed, true);
        expect(userPlants.first.potSize, 'Ada Lubang Drainase');
      },
    );
  });
}
