import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/daily_care/data/repositories/daily_care_repository_impl.dart';
import 'package:plenty/features/daily_care/domain/repositories/daily_care_repository.dart';
import 'package:plenty/features/garden/data/repositories/plant_repository_impl.dart';
import 'package:plenty/features/garden/data/repositories/site_repository_impl.dart';
import 'package:plenty/features/garden/data/repositories/streak_repository_impl.dart';
import 'package:plenty/features/garden/domain/models/perenual/plant_catalog_model.dart';
import 'package:plenty/features/garden/domain/repositories/plant_repository.dart';
import 'package:plenty/features/garden/domain/repositories/site_repository.dart';
import 'package:plenty/features/garden/domain/repositories/streak_repository.dart';
import 'package:plenty/features/garden/presentation/controllers/home_controller.dart';
import 'package:plenty/features/profile/data/repositories/badge_repository_impl.dart';
import 'package:plenty/features/profile/data/repositories/user_repository_impl.dart';
import 'package:plenty/features/profile/domain/repositories/badge_repository.dart';
import 'package:plenty/features/profile/domain/repositories/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late IPlantRepository plantRepo;
  late IDailyCareRepository careRepo;
  late IStreakRepository streakRepo;
  late IBadgeRepository badgeRepo;
  late IUserRepository userRepo;
  late ISiteRepository siteRepo;
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
    await db.insert(DatabaseHelper.tableUsers, {
      'id': 1,
      'email': 'user@plenty.app',
      'display_name': 'Alice',
      'streak_count': 3,
      'longest_streak': 3,
      'last_streak_date': '2026-08-19',
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    plantRepo = PlantRepositoryImpl(dbHelper: dbHelper);
    careRepo = DailyCareRepositoryImpl(dbHelper: dbHelper);
    streakRepo = StreakRepositoryImpl(dbHelper: dbHelper);
    badgeRepo = BadgeRepositoryImpl(dbHelper: dbHelper);
    userRepo = UserRepositoryImpl(dbHelper: dbHelper);
    siteRepo = SiteRepositoryImpl(dbHelper: dbHelper);
    await plantRepo.getCatalogPlants(); // seeds catalog

    controller = HomeController(
      plantRepo: plantRepo,
      careRepo: careRepo,
      streakRepo: streakRepo,
      badgeRepo: badgeRepo,
      userRepo: userRepo,
      siteRepo: siteRepo,
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

    test('Room filter updates filtered plants based on plant site', () async {
      await plantRepo.addPlant(
        userId: '1',
        species: PlantCatalogModel(
          id: 'cat_monstera',
          commonName: 'Monstera Deliciosa',
          cachedAt: DateTime.now(),
        ),
        nickname: 'Living Room Plant',
        isIndoor: true,
        site: 'Ruang Tamu',
      );

      await plantRepo.addPlant(
        userId: '1',
        species: PlantCatalogModel(
          id: 'cat_snake',
          commonName: 'Snake Plant',
          cachedAt: DateTime.now(),
        ),
        nickname: 'Bedroom Plant',
        isIndoor: true,
        site: 'Kamar Tidur',
      );

      await controller.loadDashboard();
      expect(controller.state.userPlants.length, 2);
      expect(controller.state.filteredPlants.length, 2);

      controller.setRoomFilter('Ruang Tamu');
      expect(controller.state.selectedRoomFilter, 'Ruang Tamu');
      expect(controller.state.filteredPlants.length, 1);
      expect(
        controller.state.filteredPlants.first.nickname,
        'Living Room Plant',
      );

      controller.setRoomFilter('Kamar');
      expect(controller.state.selectedRoomFilter, 'Kamar');
      expect(controller.state.filteredPlants.length, 1);
      expect(controller.state.filteredPlants.first.nickname, 'Bedroom Plant');

      controller.setRoomFilter('Semua');
      expect(controller.state.filteredPlants.length, 2);
    });
  });
}
