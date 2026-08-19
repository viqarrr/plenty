import 'package:plenty/core/constants/xp_config.dart';
import 'package:plenty/data/datasources/database_helper.dart';
import 'package:plenty/data/models/care_action_log_model.dart';
import 'package:plenty/data/models/growth_log_model.dart';
import 'package:sqflite/sqflite.dart';

/// Repository managing routine care actions, daily task completions, and gamified XP progression.
class CareRepository {
  final DatabaseHelper _dbHelper;

  CareRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Returns today's active task types for a specific user plant.
  /// Result is strictly: ['bersih_bersih', 'monitor_tinggi', if due: 'siram'].
  /// (Note: 'cek_hama' is completely removed from the code logic).
  Future<List<String>> getTodaysTaskTypes(String userPlantId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    // Default daily routine tasks
    final tasks = <String>['bersih_bersih', 'monitor_tinggi'];

    // Query watering schedule
    final scheduleRows = await db.query(
      DatabaseHelper.tableCareSchedules,
      where: 'user_plant_id = ? AND task_type = ? AND is_active = 1',
      whereArgs: [userPlantId, 'siram'],
    );

    if (scheduleRows.isNotEmpty) {
      final nextDueStr = scheduleRows.first['next_due_date'] as String?;
      if (nextDueStr == null) {
        tasks.add('siram');
      } else {
        final nextDue = DateTime.tryParse(nextDueStr);
        if (nextDue != null) {
          final isDueOrPast = nextDue.isBefore(now) ||
              (nextDue.year == now.year &&
                  nextDue.month == now.month &&
                  nextDue.day == now.day);
          if (isDueOrPast) {
            tasks.add('siram');
          }
        }
      }
    }

    return tasks;
  }

  /// Completes the height monitoring task:
  /// 1. Saves a new GrowthLogModel (source: 'daily_task').
  /// 2. Logs a CareActionLogModel (task_type: 'monitor_tinggi').
  /// 3. Updates the plant's level and XP using XpConfig helper metrics.
  /// 4. Updates the schedule's last_performed_at and next_due_date.
  /// All wrapped in an atomic Database.transaction() block.
  Future<void> completeHeightTask({
    required String userPlantId,
    required double heightCm,
    String? note,
    String? photoPath,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final logDate = now.toIso8601String().substring(0, 10);
    final xpAwarded = XpConfig.xpPerTask['monitor_tinggi'] ?? 15;

    await db.transaction((txn) async {
      // 1. Insert growth_logs entry with source='daily_task'
      final growthLog = GrowthLogModel(
        id: 'growth_${now.millisecondsSinceEpoch}',
        userPlantId: userPlantId,
        photoPath: photoPath,
        heightCm: heightCm,
        leafCount: null,
        note: note,
        source: 'daily_task',
        loggedAt: now,
      );
      await txn.insert(DatabaseHelper.tableGrowthLogs, growthLog.toMap());

      // 2. Insert care_action_logs entry
      final careLog = CareActionLogModel(
        id: 'care_log_${now.millisecondsSinceEpoch}_height',
        userPlantId: userPlantId,
        taskType: 'monitor_tinggi',
        completedAt: now,
        logDate: logDate,
        xpAwarded: xpAwarded,
        notes: note,
      );
      await txn.insert(DatabaseHelper.tableCareActionLogs, careLog.toMap());

      // 3. Atomically update plant's XP and Level
      final plantRows = await txn.query(
        DatabaseHelper.tableUserPlants,
        where: 'id = ?',
        whereArgs: [userPlantId],
      );

      if (plantRows.isNotEmpty) {
        final currentXp = (plantRows.first['xp'] as int? ?? 0);
        final newXp = currentXp + xpAwarded;
        final newLevel = XpConfig.levelForXp(newXp);

        await txn.update(
          DatabaseHelper.tableUserPlants,
          {
            'xp': newXp,
            'level': newLevel,
          },
          where: 'id = ?',
          whereArgs: [userPlantId],
        );
      }

      // 4. Update care schedule
      await txn.update(
        DatabaseHelper.tableCareSchedules,
        {
          'last_performed_at': now.toIso8601String(),
          'next_due_date':
              now.add(const Duration(days: 1)).toIso8601String(),
        },
        where: 'user_plant_id = ? AND task_type = ?',
        whereArgs: [userPlantId, 'monitor_tinggi'],
      );
    });
  }

  /// Completes a routine care task.
  Future<void> completeRoutineTask({
    required String userPlantId,
    required String taskType,
    String? notes,
  }) async {
    if (taskType == 'siram') {
      return completeWateringTask(userPlantId: userPlantId, notes: notes);
    }
    return completeSimpleTask(userPlantId: userPlantId, taskType: taskType, notes: notes);
  }

  /// Completes a simple tap-to-complete care task (e.g. 'bersih_bersih').
  Future<void> completeSimpleTask({
    required String userPlantId,
    required String taskType,
    String? notes,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final logDate = now.toIso8601String().substring(0, 10);
    final xpAwarded = XpConfig.xpPerTask[taskType] ?? 10;

    await db.transaction((txn) async {
      // 1. Insert care action log
      final careLog = CareActionLogModel(
        id: 'care_log_${now.millisecondsSinceEpoch}_$taskType',
        userPlantId: userPlantId,
        taskType: taskType,
        completedAt: now,
        logDate: logDate,
        xpAwarded: xpAwarded,
        notes: notes,
      );
      await txn.insert(DatabaseHelper.tableCareActionLogs, careLog.toMap());

      // 2. Update plant XP and Level
      final plantRows = await txn.query(
        DatabaseHelper.tableUserPlants,
        where: 'id = ?',
        whereArgs: [userPlantId],
      );

      if (plantRows.isNotEmpty) {
        final currentXp = (plantRows.first['xp'] as int? ?? 0);
        final newXp = currentXp + xpAwarded;
        final newLevel = XpConfig.levelForXp(newXp);

        await txn.update(
          DatabaseHelper.tableUserPlants,
          {
            'xp': newXp,
            'level': newLevel,
          },
          where: 'id = ?',
          whereArgs: [userPlantId],
        );
      }

      // 3. Update care schedule
      await txn.update(
        DatabaseHelper.tableCareSchedules,
        {
          'last_performed_at': now.toIso8601String(),
          'next_due_date':
              now.add(const Duration(days: 1)).toIso8601String(),
        },
        where: 'user_plant_id = ? AND task_type = ?',
        whereArgs: [userPlantId, taskType],
      );
    });
  }

  /// Completes the watering task ('siram') and recalculates next due date.
  Future<void> completeWateringTask({
    required String userPlantId,
    String? notes,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final logDate = now.toIso8601String().substring(0, 10);
    final xpAwarded = XpConfig.xpPerTask['siram'] ?? 10;

    await db.transaction((txn) async {
      // 1. Insert care action log
      final careLog = CareActionLogModel(
        id: 'care_log_${now.millisecondsSinceEpoch}_siram',
        userPlantId: userPlantId,
        taskType: 'siram',
        completedAt: now,
        logDate: logDate,
        xpAwarded: xpAwarded,
        notes: notes,
      );
      await txn.insert(DatabaseHelper.tableCareActionLogs, careLog.toMap());

      // 2. Update plant XP and Level
      final plantRows = await txn.query(
        DatabaseHelper.tableUserPlants,
        where: 'id = ?',
        whereArgs: [userPlantId],
      );

      if (plantRows.isNotEmpty) {
        final currentXp = (plantRows.first['xp'] as int? ?? 0);
        final newXp = currentXp + xpAwarded;
        final newLevel = XpConfig.levelForXp(newXp);

        await txn.update(
          DatabaseHelper.tableUserPlants,
          {
            'xp': newXp,
            'level': newLevel,
          },
          where: 'id = ?',
          whereArgs: [userPlantId],
        );
      }

      // 3. Look up interval and reset next_due_date
      final scheduleRows = await txn.query(
        DatabaseHelper.tableCareSchedules,
        where: 'user_plant_id = ? AND task_type = ?',
        whereArgs: [userPlantId, 'siram'],
      );

      final intervalDays = scheduleRows.isNotEmpty
          ? (scheduleRows.first['interval_days'] as int? ?? 3)
          : 3;

      await txn.update(
        DatabaseHelper.tableCareSchedules,
        {
          'last_performed_at': now.toIso8601String(),
          'next_due_date':
              now.add(Duration(days: intervalDays)).toIso8601String(),
        },
        where: 'user_plant_id = ? AND task_type = ?',
        whereArgs: [userPlantId, 'siram'],
      );
    });
  }

  /// Returns total number of completed care tasks for a specific plant.
  Future<int> getTaskCompletedCount(String userPlantId) async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseHelper.tableCareActionLogs} WHERE user_plant_id = ?',
        [userPlantId],
      ),
    );
    return count ?? 0;
  }

  /// Checks if all active plants for a user have completed all daily tasks today.
  Future<bool> isAllTasksCompleteTodayForUser(String userId) async {
    final db = await _dbHelper.database;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final parsedUserId = int.tryParse(userId.toString()) ?? 1;

    // Get active plants
    final activePlants = await db.query(
      DatabaseHelper.tableUserPlants,
      columns: ['id'],
      where: 'user_id = ? AND is_archived = 0',
      whereArgs: [parsedUserId],
    );

    if (activePlants.isEmpty) return false;

    for (final plantMap in activePlants) {
      final plantId = plantMap['id'] as String;
      final requiredTaskTypes = await getTodaysTaskTypes(plantId);

      final loggedTasks = await db.query(
        DatabaseHelper.tableCareActionLogs,
        columns: ['task_type'],
        where: 'user_plant_id = ? AND log_date = ?',
        whereArgs: [plantId, today],
      );

      final completedTypes =
          loggedTasks.map((t) => t['task_type'] as String).toSet();

      for (final reqType in requiredTaskTypes) {
        if (!completedTypes.contains(reqType)) {
          return false;
        }
      }
    }

    return true;
  }
}
