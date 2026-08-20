import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/data/datasources/database_helper.dart';
import 'package:plenty/data/datasources/preference_handler.dart';
import 'package:plenty/data/models/plant_catalog_model.dart';
import 'package:plenty/data/repositories/care_repository.dart';
import 'package:plenty/data/repositories/plant_repository.dart';
import 'package:plenty/presentation/home/home_controller.dart';
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
      'streak_count': 3,
      'profile_name': 'Alice',
    });
    await PreferenceHandler.init();

    final uniqueName = 'home_ctrl_${DateTime.now().microsecondsSinceEpoch}.db';
    dbHelper = DatabaseHelper.forTesting(uniqueName);
    await dbHelper.deleteDb();

    // Seed default user and streak
    final db = await dbHelper.database;
    await db.insert(
      DatabaseHelper.tableUsers,
      {
        'id': 1,
        'email': 'user@plenty.app',
        'display_name': 'Alice',
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert(
      DatabaseHelper.tableUserStreaks,
      {
        'id': 'streak_1',
        'user_id': 1,
        'current_streak': 3,
        'longest_streak': 3,
        'current_tier': 2,
        'last_streak_date': '2026-08-19',
        'freeze_tokens_available': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    plantRepo = PlantRepository(dbHelper: dbHelper);
    careRepo = CareRepository(dbHelper: dbHelper);
    await plantRepo.getCatalogPlants(); // seeds catalog

    controller = HomeController(
      plantRepo: plantRepo,
      careRepo: careRepo,
      userId: '1',
    );
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('HomeController Unit Tests', () {
    test('Yields HomeStatus.empty when user has 0 plants', () async {
      await controller.loadDashboard();
      expect(controller.state.status, HomeStatus.empty);
      expect(controller.state.userPlants, isEmpty);
      expect(controller.state.dailyTasks, isEmpty);
      expect(controller.state.streakCount, 3);
      expect(controller.state.profileName, 'Alice');
    });

    test(
      'Yields HomeStatus.populated when plants are added and generates routine tasks',
      () async {
        // Add a plant
        await plantRepo.addPlant(
          userId: '1',
          species: PlantCatalogModel(
            id: 'cat_monstera',
            commonName: 'Monstera Deliciosa',
            cachedAt: DateTime.now(),
          ),
          nickname: 'Monstera Queen',
          isIndoor: true,
          initialHeightCm: 35.0,
        );

        await controller.loadDashboard();

        expect(controller.state.status, HomeStatus.populated);
        expect(controller.state.userPlants.length, 1);
        expect(controller.state.userPlants.first.nickname, 'Monstera Queen');
        expect(controller.state.dailyTasks.length, greaterThanOrEqualTo(1));
      },
    );

    test('Room filter updates filtered plants', () async {
      await plantRepo.addPlant(
        userId: '1',
        species: PlantCatalogModel(
          id: 'cat_monstera',
          commonName: 'Monstera Deliciosa',
          cachedAt: DateTime.now(),
        ),
        nickname: 'Living Room Plant',
        isIndoor: true,
      );

      await controller.loadDashboard();
      controller.setRoomFilter('Ruang Tamu');
      expect(controller.state.selectedRoomFilter, 'Ruang Tamu');
    });
  });
}
