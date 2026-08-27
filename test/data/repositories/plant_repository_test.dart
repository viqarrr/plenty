import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/features/garden/data/repositories/plant_repository_impl.dart';
import 'package:plenty/features/garden/domain/models/time_capsule_model.dart';
import 'package:plenty/features/garden/domain/repositories/plant_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late IPlantRepository plantRepository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper.forTesting('plant_repo_test.db');
    await dbHelper.deleteDb();
    plantRepository = PlantRepositoryImpl(dbHelper: dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('PlantRepository.addPlant Transaction Tests', () {
    test(
      'addPlant performs atomic insertion across user_plants, initial growth_logs, care_schedules, and time_capsules',
      () async {
        // 1. Insert user first
        final db = await dbHelper.database;
        await db.insert(DatabaseHelper.tableUsers, {
          'id': 1,
          'email': 'test@plenty.app',
          'display_name': 'Test User',
          'created_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        final unlockDate = DateTime.now().add(const Duration(days: 60));
        final resultRes = await plantRepository.addPlant(
          userId: '1',
          nickname: 'Monsty Deliciosa',
          isIndoor: true,
          sunlightCondition: 'Sinar Tidak Langsung',
          potSize: 'Ada Lubang Drainase',
          siteId: 'site_default_ruang_tamu',
          initialHeightCm: 28.5,
          coverPhotoPath: 'assets/images/monstera.png',
          timeCapsule: TimeCapsuleDraft(
            photoPath: 'assets/images/capsule.png',
            note: 'Harapan untuk tanaman pertamaku',
            unlockAt: unlockDate,
          ),
          defaultWateringInterval: 7,
        );
        final result = resultRes.dataOrNull!;

        // Verify returned result
        expect(result.isFirstPlant, isTrue);
        expect(result.isFirstTimeCapsule, isTrue);
        expect(result.plant.nickname, 'Monsty Deliciosa');
        expect(result.plant.initialHeightCm, 28.5);
        expect(result.plant.level, 1);
        expect(result.plant.xp, 0);

        // Verify time capsule badge unlocked in SQLite user_badges
        final userBadges = await db.query(
          DatabaseHelper.tableUserBadges,
          where: 'user_id = ? AND badge_id = ?',
          whereArgs: [1, 'time_capsule'],
        );
        expect(userBadges.isNotEmpty, isTrue);
        expect(userBadges.first['is_unlocked'], 1);

        // Verify saved in SQLite
        final userPlantsRes = await plantRepository.getUserPlants('1');
        final userPlants = userPlantsRes.dataOrNull ?? [];
        expect(userPlants.length, 1);
        final plantRows = await db.query(DatabaseHelper.tableUserPlants);
        expect(plantRows.first['nickname'], 'Monsty Deliciosa');
        expect(plantRows.first['initial_height_cm'], 28.5);

        // Verify growth_logs table row (source: 'initial')
        final growthRows = await db.query(DatabaseHelper.tableGrowthLogs);
        expect(growthRows.length, 1);
        expect(growthRows.first['source'], 'initial');
        expect(growthRows.first['height_cm'], 28.5);
        expect(growthRows.first['user_plant_id'], result.plant.id);

        // Verify care_schedules table rows (siram, bersih_bersih, monitor_tinggi)
        final scheduleRows = await db.query(DatabaseHelper.tableCareSchedules);
        expect(scheduleRows.length, 3);
        final taskTypes = scheduleRows
            .map((s) => s['task_type'] as String)
            .toSet();
        expect(taskTypes, containsAll(['siram', 'bersih', 'monitor']));
        expect(taskTypes.contains('cek_hama'), isFalse);

        // Verify time_capsules table row
        final capsuleRows = await db.query(DatabaseHelper.tableTimeCapsules);
        expect(capsuleRows.length, 1);
        expect(capsuleRows.first['user_plant_id'], result.plant.id);
        expect(capsuleRows.first['note'], 'Harapan untuk tanaman pertamaku');

        // 2. Add second plant and verify isFirstPlant is false
        final secondResultRes = await plantRepository.addPlant(
          userId: 'user_1',
          nickname: 'Sansevieria',
          isIndoor: true,
          defaultWateringInterval: 14,
        );
        final secondResult = secondResultRes.dataOrNull!;
        expect(secondResult.isFirstPlant, isFalse);

        // 3. Test updatePlantInfo & updatePlantPhoto
        await plantRepository.updatePlantInfo(
          plantId: result.plant.id,
          nickname: 'Super Monstera Deluxe',
          coverPhotoPath: 'https://example.com/new_photo.jpg',
          updatePhoto: true,
        );
        final updatedPlantRes = await plantRepository.getPlantById(
          result.plant.id,
        );
        final updatedPlant = updatedPlantRes.dataOrNull;
        expect(updatedPlant?.nickname, 'Super Monstera Deluxe');
        expect(
          updatedPlant?.coverPhotoPath,
          'https://example.com/new_photo.jpg',
        );

        // 4. Test cascading deletePlant
        await plantRepository.deletePlant(result.plant.id);
        final remainingPlantsRes = await plantRepository.getUserPlants('1');
        final remainingPlants = remainingPlantsRes.dataOrNull ?? [];
        expect(remainingPlants.any((p) => p.id == result.plant.id), isFalse);

        // Verify cascading deletion across logs, schedules, capsules
        final deletedGrowthLogs = await db.query(
          DatabaseHelper.tableGrowthLogs,
          where: 'user_plant_id = ?',
          whereArgs: [result.plant.id],
        );
        expect(deletedGrowthLogs.isEmpty, isTrue);

        final deletedSchedules = await db.query(
          DatabaseHelper.tableCareSchedules,
          where: 'user_plant_id = ?',
          whereArgs: [result.plant.id],
        );
        expect(deletedSchedules.isEmpty, isTrue);

        final deletedCapsules = await db.query(
          DatabaseHelper.tableTimeCapsules,
          where: 'user_plant_id = ?',
          whereArgs: [result.plant.id],
        );
        expect(deletedCapsules.isEmpty, isTrue);

        // 5. Test adding another plant after deleting all plants does NOT re-trigger isFirstPlant
        await plantRepository.deletePlant(secondResult.plant.id);
        final emptyPlantsRes = await plantRepository.getUserPlants('1');
        expect(emptyPlantsRes.dataOrNull?.isEmpty, isTrue);

        final thirdResultRes = await plantRepository.addPlant(
          userId: '1',
          nickname: 'Kaktus Ketiga',
          isIndoor: true,
          defaultWateringInterval: 14,
        );
        final thirdResult = thirdResultRes.dataOrNull!;
        expect(thirdResult.isFirstPlant, isFalse);
      },
    );
  });
}
