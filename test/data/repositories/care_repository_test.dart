import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/constants/xp_config.dart';
import 'package:plenty/data/datasources/database_helper.dart';
import 'package:plenty/data/repositories/care_repository.dart';
import 'package:plenty/data/repositories/plant_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late PlantRepository plantRepository;
  late CareRepository careRepository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper.forTesting('care_repo_test.db');
    await dbHelper.deleteDb();
    plantRepository = PlantRepository(dbHelper: dbHelper);
    careRepository = CareRepository(dbHelper: dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('CareRepository Integration Tests', () {
    test('getTodaysTaskTypes returns strictly bersih_bersih, monitor_tinggi, and conditional siram (no cek_hama)', () async {
      final db = await dbHelper.database;
      await db.insert(DatabaseHelper.tableUsers, {
        'id': 'user_care_1',
        'email': 'care@plenty.app',
        'display_name': 'Care User',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Add a plant with watering due in 5 days
      final addResult = await plantRepository.addPlant(
        userId: 'user_care_1',
        nickname: 'Aloe Vera',
        isIndoor: true,
        defaultWateringInterval: 5,
      );
      final plantId = addResult.plant.id;

      // 1. When watering is NOT due today: returns ['bersih_bersih', 'monitor_tinggi']
      var tasks = await careRepository.getTodaysTaskTypes(plantId);
      expect(tasks, ['bersih_bersih', 'monitor_tinggi']);
      expect(tasks.contains('cek_hama'), isFalse);
      expect(tasks.contains('siram'), isFalse);

      // 2. Set watering next_due_date to today: returns ['bersih_bersih', 'monitor_tinggi', 'siram']
      await db.update(
        DatabaseHelper.tableCareSchedules,
        {'next_due_date': DateTime.now().toIso8601String()},
        where: 'user_plant_id = ? AND task_type = ?',
        whereArgs: [plantId, 'siram'],
      );

      tasks = await careRepository.getTodaysTaskTypes(plantId);
      expect(tasks, containsAll(['bersih_bersih', 'monitor_tinggi', 'siram']));
      expect(tasks.contains('cek_hama'), isFalse);
    });

    test('completeHeightTask atomically saves growth_log (source=daily_task), logs care_action_log, and updates plant level/XP', () async {
      final db = await dbHelper.database;
      await db.insert(DatabaseHelper.tableUsers, {
        'id': 'user_height_1',
        'email': 'height@plenty.app',
        'display_name': 'Height User',
        'created_at': DateTime.now().toIso8601String(),
      });

      final addResult = await plantRepository.addPlant(
        userId: 'user_height_1',
        nickname: 'Bonsai Ficus',
        isIndoor: true,
        initialHeightCm: 15.0,
      );
      final plantId = addResult.plant.id;

      // Initial state: Level 1, 0 XP
      var plant = await plantRepository.getPlantById(plantId);
      expect(plant?.level, 1);
      expect(plant?.xp, 0);

      // Complete height task with 16.5 cm
      await careRepository.completeHeightTask(
        userPlantId: plantId,
        heightCm: 16.5,
        note: 'Tunas baru bertambah panjang',
      );

      // 1. Verify growth_logs row has source='daily_task'
      final growthLogs = await db.query(
        DatabaseHelper.tableGrowthLogs,
        where: 'user_plant_id = ? AND source = ?',
        whereArgs: [plantId, 'daily_task'],
      );
      expect(growthLogs.length, 1);
      expect(growthLogs.first['height_cm'], 16.5);
      expect(growthLogs.first['note'], 'Tunas baru bertambah panjang');

      // 2. Verify care_action_logs has task_type='monitor_tinggi' and 15 XP
      final careLogs = await db.query(
        DatabaseHelper.tableCareActionLogs,
        where: 'user_plant_id = ?',
        whereArgs: [plantId],
      );
      expect(careLogs.length, 1);
      expect(careLogs.first['task_type'], 'monitor_tinggi');
      expect(careLogs.first['xp_awarded'], XpConfig.xpPerTask['monitor_tinggi']);

      // 3. Verify plant XP and level updated
      plant = await plantRepository.getPlantById(plantId);
      expect(plant?.xp, 15);
      expect(plant?.level, 1);

      // 4. Repeat tasks to trigger level-up boundary (>= 100 XP)
      for (int i = 0; i < 6; i++) {
        await careRepository.completeHeightTask(
          userPlantId: plantId,
          heightCm: 17.0 + i,
        );
      }

      plant = await plantRepository.getPlantById(plantId);
      // 15 + 6 * 15 = 105 XP -> Level 2
      expect(plant?.xp, 105);
      expect(plant?.level, 2);
      expect(XpConfig.levelForXp(plant!.xp), 2);
    });
  });
}
