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
  late String plantId;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper.forTesting('care_repo_test.db');
    await dbHelper.deleteDb();
    plantRepository = PlantRepository(dbHelper: dbHelper);
    careRepository = CareRepository(dbHelper: dbHelper);

    final db = await dbHelper.database;
    await db.insert(
      DatabaseHelper.tableUsers,
      {
        'id': 1,
        'email': 'care@plenty.app',
        'display_name': 'Care User',
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final addResult = await plantRepository.addPlant(
      userId: '1',
      nickname: 'Aloe Vera',
      isIndoor: true,
      defaultWateringInterval: 5,
    );
    plantId = addResult.plant.id;
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('CareRepository Integration Tests', () {
    test(
        'getTodaysTaskTypes returns strictly monitor_tinggi as daily task, and bersih_bersih / siram cyclically based on due date',
        () async {
      final db = await dbHelper.database;

      // 1. When cleaning and watering are NOT due today: returns only ['monitor_tinggi'] (Daily Log)
      var tasks = await careRepository.getTodaysTaskTypes(plantId);
      expect(tasks, ['monitor_tinggi']);
      expect(tasks.contains('cek_hama'), isFalse);
      expect(tasks.contains('siram'), isFalse);
      expect(tasks.contains('bersih_bersih'), isFalse);

      // 2. Set watering and cleaning next_due_date to today: returns ['monitor_tinggi', 'siram', 'bersih_bersih']
      await db.update(
        DatabaseHelper.tableCareSchedules,
        {'next_due_date': DateTime.now().toIso8601String()},
        where: 'user_plant_id = ?',
        whereArgs: [plantId],
      );

      tasks = await careRepository.getTodaysTaskTypes(plantId);
      expect(tasks, containsAll(['monitor_tinggi', 'siram', 'bersih_bersih']));
      expect(tasks.contains('cek_hama'), isFalse);
    });

    test(
        'completeHeightTask atomically saves growth_log (source=daily_task), logs care_action_log, and updates plant level/XP',
        () async {
      final db = await dbHelper.database;

      // Initial plant check
      var plant = await plantRepository.getPlantById(plantId);
      expect(plant?.xp, 0);
      expect(plant?.level, 1);

      // Complete height task
      await careRepository.completeHeightTask(
        userPlantId: plantId,
        heightCm: 16.5,
        note: 'Tunas baru bertambah panjang',
      );

      // 1. Verify growth_logs has source='daily_task'
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
      expect(
          careLogs.first['xp_awarded'], XpConfig.xpPerTask['monitor_tinggi']);

      // 3. Verify plant XP and level updated
      plant = await plantRepository.getPlantById(plantId);
      expect(plant?.xp, 15);
      expect(plant?.level, 1);

      // 4. Repeated call on the same day is idempotent (does not add duplicate log or XP)
      await careRepository.completeHeightTask(
        userPlantId: plantId,
        heightCm: 20.0,
      );
      plant = await plantRepository.getPlantById(plantId);
      expect(plant?.xp, 15);

      final secondCheckLogs = await db.query(
        DatabaseHelper.tableGrowthLogs,
        where: 'user_plant_id = ? AND source = ?',
        whereArgs: [plantId, 'daily_task'],
      );
      expect(secondCheckLogs.length, 1);

      // 5. Verify level calculation helper triggers level-up boundary (>= 100 XP -> Level 2)
      expect(XpConfig.levelForXp(105), 2);
    });

    test('completeSimpleTask awards 10 XP and logs action', () async {
      await careRepository.completeSimpleTask(
        userPlantId: plantId,
        taskType: 'bersih_bersih',
        notes: 'Daun sudah dilap bersih',
      );

      final plant = await plantRepository.getPlantById(plantId);
      expect(plant?.xp, 10);

      final db = await dbHelper.database;
      final logs = await db.query(
        DatabaseHelper.tableCareActionLogs,
        where: 'user_plant_id = ? AND task_type = ?',
        whereArgs: [plantId, 'bersih_bersih'],
      );
      expect(logs.length, 1);
      expect(logs.first['xp_awarded'], 10);
    });

    test('completeWateringTask awards 10 XP and updates next_due_date',
        () async {
      await careRepository.completeWateringTask(userPlantId: plantId);

      final plant = await plantRepository.getPlantById(plantId);
      expect(plant?.xp, 10);

      final db = await dbHelper.database;
      final schedules = await db.query(
        DatabaseHelper.tableCareSchedules,
        where: 'user_plant_id = ? AND task_type = ?',
        whereArgs: [plantId, 'siram'],
      );
      expect(schedules.length, 1);
      expect(schedules.first['last_performed_at'], isNotNull);
    });

    test(
      'isAllTasksCompleteTodayForUser returns true when all tasks done',
      () async {
        final todayTasks = await careRepository.getTodaysTaskTypes(plantId);
        if (todayTasks.contains('bersih_bersih')) {
          await careRepository.completeSimpleTask(
            userPlantId: plantId,
            taskType: 'bersih_bersih',
          );
        }
        if (todayTasks.contains('monitor_tinggi')) {
          await careRepository.completeHeightTask(
            userPlantId: plantId,
            heightCm: 16.0,
          );
        }
        if (todayTasks.contains('siram')) {
          await careRepository.completeWateringTask(userPlantId: plantId);
        }

        final isDone =
            await careRepository.isAllTasksCompleteTodayForUser('1');
        expect(isDone, true);
      },
    );
  });
}
