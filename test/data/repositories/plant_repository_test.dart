import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/data/datasources/database_helper.dart';
import 'package:plenty/data/models/time_capsule_model.dart';
import 'package:plenty/data/repositories/plant_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late PlantRepository plantRepository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper.forTesting('plant_repo_test.db');
    await dbHelper.deleteDb();
    plantRepository = PlantRepository(dbHelper: dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('PlantRepository.addPlant Transaction Tests', () {
    test('addPlant performs atomic insertion across user_plants, initial growth_logs, care_schedules, and time_capsules', () async {
      // 1. Insert user first
      final db = await dbHelper.database;
      await db.insert(DatabaseHelper.tableUsers, {
        'id': 'user_1',
        'email': 'test@plenty.app',
        'display_name': 'Test User',
        'created_at': DateTime.now().toIso8601String(),
      });

      final unlockDate = DateTime.now().add(const Duration(days: 60));
      final result = await plantRepository.addPlant(
        userId: 'user_1',
        nickname: 'Monsty Deliciosa',
        isIndoor: true,
        sunlightCondition: 'Sinar Tidak Langsung',
        potSize: 'Ada Lubang Drainase',
        windowDistance: 'Dekat Jendela (1-1.5 meter)',
        initialHeightCm: 28.5,
        coverPhotoPath: 'assets/images/monstera.png',
        timeCapsule: TimeCapsuleDraft(
          photoPath: 'assets/images/capsule.png',
          note: 'Harapan untuk tanaman pertamaku',
          unlockAt: unlockDate,
        ),
        defaultWateringInterval: 7,
      );

      // Verify returned result
      expect(result.isFirstPlant, isTrue);
      expect(result.plant.nickname, 'Monsty Deliciosa');
      expect(result.plant.initialHeightCm, 28.5);
      expect(result.plant.level, 1);
      expect(result.plant.xp, 0);

      // Verify user_plants table row
      final plantRows = await db.query(DatabaseHelper.tableUserPlants);
      expect(plantRows.length, 1);
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
      final taskTypes = scheduleRows.map((s) => s['task_type'] as String).toSet();
      expect(taskTypes, containsAll(['siram', 'bersih_bersih', 'monitor_tinggi']));
      expect(taskTypes.contains('cek_hama'), isFalse);

      // Verify time_capsules table row
      final capsuleRows = await db.query(DatabaseHelper.tableTimeCapsules);
      expect(capsuleRows.length, 1);
      expect(capsuleRows.first['user_plant_id'], result.plant.id);
      expect(capsuleRows.first['note'], 'Harapan untuk tanaman pertamaku');

      // 2. Add second plant and verify isFirstPlant is false
      final secondResult = await plantRepository.addPlant(
        userId: 'user_1',
        nickname: 'Sansevieria',
        isIndoor: true,
        defaultWateringInterval: 14,
      );
      expect(secondResult.isFirstPlant, isFalse);
    });
  });
}
