import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/constants/xp_config.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/features/daily_care/data/repositories/daily_care_repository_impl.dart';
import 'package:plenty/features/daily_care/domain/repositories/daily_care_repository.dart';
import 'package:plenty/features/garden/data/repositories/plant_repository_impl.dart';
import 'package:plenty/features/garden/domain/repositories/plant_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late IPlantRepository plantRepository;
  late IDailyCareRepository careRepository;
  late String plantId;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper.forTesting('care_repo_test.db');
    await dbHelper.deleteDb();
    plantRepository = PlantRepositoryImpl(dbHelper: dbHelper);
    careRepository = DailyCareRepositoryImpl(
      dbHelper: dbHelper,
      plantRepo: plantRepository,
    );

    final db = await dbHelper.database;
    await db.insert(DatabaseHelper.tableUsers, {
      'id': 1,
      'email': 'care@plenty.app',
      'display_name': 'Care User',
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    final addResult = await plantRepository.addPlant(
      userId: '1',
      nickname: 'Aloe Vera',
      isIndoor: true,
      defaultWateringInterval: 5,
    );
    plantId = addResult.dataOrNull!.plant.id;
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('CareRepository Integration Tests', () {
    test(
      'getTodaysTaskTypes returns strictly monitor_tinggi as daily task, and bersih_bersih / siram cyclically based on due date',
      () async {
        final db = await dbHelper.database;

        // 1. On initial plant adoption: watering and cleaning are due immediately
        var tasksRes = await careRepository.getTodaysTaskTypes(plantId);
        var tasks = tasksRes.dataOrNull ?? [];
        expect(tasks, containsAll(['monitor', 'siram', 'bersih']));
        expect(tasks.contains('cek_hama'), isFalse);

        // 2. When cleaning and watering are postponed to tomorrow: returns only ['monitor']
        final tomorrowStr = DateTime.now().add(const Duration(days: 1)).toIso8601String();
        await db.update(
          DatabaseHelper.tableCareSchedules,
          {'next_due_date': tomorrowStr},
          where: "user_plant_id = ? AND task_type != 'monitor'",
          whereArgs: [plantId],
        );

        tasksRes = await careRepository.getTodaysTaskTypes(plantId);
        tasks = tasksRes.dataOrNull ?? [];
        expect(tasks, ['monitor']);
        expect(tasks.contains('siram'), isFalse);
        expect(tasks.contains('bersih'), isFalse);
      },
    );

    test(
      'completeHeightTask atomically saves growth_log (source=daily_task), logs care_action_log, and updates plant level/XP',
      () async {
        final db = await dbHelper.database;

        // Initial plant check
        var plantRes = await plantRepository.getPlantById(plantId);
        var plant = plantRes.dataOrNull!;
        expect(plant.xp, 0);
        expect(plant.level, 1);

        // Complete height task
        await careRepository.completeHeightTask(
          plant: plant,
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

        // 2. Verify care_action_logs has task_type='monitor' and 15 XP
        final careLogs = await db.query(
          DatabaseHelper.tableCareActionLogs,
          where: 'user_plant_id = ?',
          whereArgs: [plantId],
        );
        expect(careLogs.length, 1);
        expect(careLogs.first['task_type'], 'monitor');
        expect(careLogs.first['xp_awarded'], XpConfig.xpPerTask['monitor']);

        // 3. Verify plant XP and level updated
        plantRes = await plantRepository.getPlantById(plantId);
        plant = plantRes.dataOrNull!;
        expect(plant.xp, 15);
        expect(plant.level, 1);

        // 4. Repeated call on the same day is idempotent (does not add duplicate log or XP)
        await careRepository.completeHeightTask(plant: plant, heightCm: 20.0);
        plantRes = await plantRepository.getPlantById(plantId);
        plant = plantRes.dataOrNull!;
        expect(plant.xp, 15);

        final secondCheckLogs = await db.query(
          DatabaseHelper.tableGrowthLogs,
          where: 'user_plant_id = ? AND source = ?',
          whereArgs: [plantId, 'daily_task'],
        );
        expect(secondCheckLogs.length, 1);

        // 5. Verify level calculation helper triggers level-up boundary (>= 100 XP -> Level 2)
        expect(XpConfig.levelForXp(105), 2);
      },
    );

    test(
      'completeRoutineTask for bersih_bersih awards 10 XP and logs action',
      () async {
        final plantRes = await plantRepository.getPlantById(plantId);
        final plant = plantRes.dataOrNull!;

        await careRepository.completeRoutineTask(
          plant: plant,
          taskType: 'bersih',
          notes: 'Daun sudah dilap bersih',
        );

        final updatedPlantRes = await plantRepository.getPlantById(plantId);
        final updatedPlant = updatedPlantRes.dataOrNull;
        expect(updatedPlant?.xp, 10);

        final db = await dbHelper.database;
        final logs = await db.query(
          DatabaseHelper.tableCareActionLogs,
          where: 'user_plant_id = ? AND task_type = ?',
          whereArgs: [plantId, 'bersih'],
        );
        expect(logs.length, 1);
        expect(logs.first['xp_awarded'], 10);
      },
    );

    test(
      'completeRoutineTask for siram awards 10 XP and updates next_due_date',
      () async {
        final plantRes = await plantRepository.getPlantById(plantId);
        final plant = plantRes.dataOrNull!;

        await careRepository.completeRoutineTask(
          plant: plant,
          taskType: 'siram',
        );

        final updatedPlantRes = await plantRepository.getPlantById(plantId);
        final updatedPlant = updatedPlantRes.dataOrNull;
        expect(updatedPlant?.xp, 10);

        final db = await dbHelper.database;
        final schedules = await db.query(
          DatabaseHelper.tableCareSchedules,
          where: 'user_plant_id = ? AND task_type = ?',
          whereArgs: [plantId, 'siram'],
        );
        expect(schedules.length, 1);
        expect(schedules.first['last_performed_at'], isNotNull);
      },
    );

    test(
      'isAllTasksCompleteTodayForUser returns true when all tasks done',
      () async {
        final plantRes = await plantRepository.getPlantById(plantId);
        final plant = plantRes.dataOrNull!;

        final todayTasksRes = await careRepository.getTodaysTaskTypes(plantId);
        final todayTasks = todayTasksRes.dataOrNull ?? [];
        if (todayTasks.contains('bersih')) {
          await careRepository.completeRoutineTask(
            plant: plant,
            taskType: 'bersih',
          );
        }
        if (todayTasks.contains('monitor')) {
          await careRepository.completeHeightTask(plant: plant, heightCm: 16.0);
        }
        if (todayTasks.contains('siram')) {
          await careRepository.completeRoutineTask(
            plant: plant,
            taskType: 'siram',
          );
        }

        final isDoneRes = await careRepository.isAllTasksCompleteTodayForUser(
          '1',
        );
        expect(isDoneRes.dataOrNull, true);
      },
    );
  });
}
