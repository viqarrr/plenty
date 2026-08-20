import 'package:plenty/core/constants/xp_config.dart';
import 'package:plenty/data/datasources/database_helper.dart';
import 'package:plenty/data/models/care_action_log_model.dart';
import 'package:plenty/data/models/care_history_item.dart';
import 'package:plenty/data/models/growth_log_model.dart';
import 'package:sqflite/sqflite.dart';

/// Repository managing routine care actions, daily task completions, and gamified XP progression.
class CareRepository {
  final DatabaseHelper _dbHelper;

  CareRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Returns today's active task types for a specific user plant.
  /// - 'monitor_tinggi' (Log Harian) is returned daily UNLESS already completed today.
  /// - 'bersih_bersih' and 'siram' are cyclic tasks returned only when due and NOT completed today.
  Future<List<String>> getTodaysTaskTypes(String userPlantId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final today = now.toIso8601String().substring(0, 10);

    // Fetch tasks already completed today for this plant
    final completedRows = await db.query(
      DatabaseHelper.tableCareActionLogs,
      columns: ['task_type'],
      where: 'user_plant_id = ? AND log_date = ?',
      whereArgs: [userPlantId, today],
    );
    final completedTypes =
        completedRows.map((r) => r['task_type'] as String).toSet();

    final tasks = <String>[];

    // 1. Daily routine task: 'monitor_tinggi' (Log Harian)
    if (!completedTypes.contains('monitor_tinggi')) {
      tasks.add('monitor_tinggi');
    }

    // 2. Cyclic routine tasks from care_schedules ('siram' and 'bersih_bersih')
    final cyclicTaskTypes = ['siram', 'bersih_bersih'];
    for (final taskType in cyclicTaskTypes) {
      if (completedTypes.contains(taskType)) {
        continue;
      }

      final scheduleRows = await db.query(
        DatabaseHelper.tableCareSchedules,
        where: 'user_plant_id = ? AND task_type = ? AND is_active = 1',
        whereArgs: [userPlantId, taskType],
      );

      if (scheduleRows.isNotEmpty) {
        final nextDueStr = scheduleRows.first['next_due_date'] as String?;
        if (nextDueStr == null) {
          tasks.add(taskType);
        } else {
          final nextDue = DateTime.tryParse(nextDueStr);
          if (nextDue != null) {
            final isDueOrPast = nextDue.isBefore(now) ||
                (nextDue.year == now.year &&
                    nextDue.month == now.month &&
                    nextDue.day == now.day);
            if (isDueOrPast) {
              tasks.add(taskType);
            }
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

    // Prevent double logging on the same day
    final existing = await db.query(
      DatabaseHelper.tableCareActionLogs,
      where: 'user_plant_id = ? AND task_type = ? AND log_date = ?',
      whereArgs: [userPlantId, 'monitor_tinggi', logDate],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return;
    }

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

      // 3. Atomically update plant's XP and Level (and cover_photo_path if photo provided)
      final plantRows = await txn.query(
        DatabaseHelper.tableUserPlants,
        where: 'id = ?',
        whereArgs: [userPlantId],
      );

      if (plantRows.isNotEmpty) {
        final currentXp = (plantRows.first['xp'] as int? ?? 0);
        final newXp = currentXp + xpAwarded;
        final newLevel = XpConfig.levelForXp(newXp);

        final updateValues = <String, dynamic>{
          'xp': newXp,
          'level': newLevel,
        };
        if (photoPath != null && photoPath.isNotEmpty) {
          updateValues['cover_photo_path'] = photoPath;
        }

        await txn.update(
          DatabaseHelper.tableUserPlants,
          updateValues,
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

  /// Updates today's growth log entry without re-awarding XP or creating duplicate records.
  Future<void> updateHeightTask({
    required String userPlantId,
    required double heightCm,
    String? note,
    String? photoPath,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final logDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await db.transaction((txn) async {
      // 1. Find today's growth log for this plant
      final existingLogs = await txn.query(
        DatabaseHelper.tableGrowthLogs,
        where: 'user_plant_id = ? AND logged_at LIKE ?',
        whereArgs: [userPlantId, '$logDate%'],
        orderBy: 'logged_at DESC',
        limit: 1,
      );

      if (existingLogs.isNotEmpty) {
        final logId = existingLogs.first['id'] as String;
        final growthValues = <String, dynamic>{
          'height_cm': heightCm,
          'note': note,
        };
        if (photoPath != null && photoPath.isNotEmpty) {
          growthValues['photo_path'] = photoPath;
        }
        await txn.update(
          DatabaseHelper.tableGrowthLogs,
          growthValues,
          where: 'id = ?',
          whereArgs: [logId],
        );
      }

      // 2. Update care_action_logs note
      await txn.update(
        DatabaseHelper.tableCareActionLogs,
        {
          'notes': note,
          'completed_at': now.toIso8601String(),
        },
        where: 'user_plant_id = ? AND task_type = ? AND log_date = ?',
        whereArgs: [userPlantId, 'monitor_tinggi', logDate],
      );

      // 3. Update user_plants cover_photo_path if photo provided
      if (photoPath != null && photoPath.isNotEmpty) {
        await txn.update(
          DatabaseHelper.tableUserPlants,
          {'cover_photo_path': photoPath},
          where: 'id = ?',
          whereArgs: [userPlantId],
        );
      }
    });
  }

  /// Returns the logged note today if recorded today.
  Future<String?> getLoggedNoteToday(String userPlantId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final logDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final rows = await db.query(
      DatabaseHelper.tableGrowthLogs,
      columns: ['note'],
      where: 'user_plant_id = ? AND logged_at LIKE ?',
      whereArgs: [userPlantId, '$logDate%'],
      orderBy: 'logged_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['note'] as String?;
  }

  /// Updates a specific growth log entry by log ID and updates plant cover photo if it's the latest log.
  Future<void> updateGrowthLog({
    required String logId,
    required String userPlantId,
    required double heightCm,
    String? note,
    String? photoPath,
  }) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final updateValues = <String, dynamic>{
        'height_cm': heightCm,
        'note': note,
      };
      if (photoPath != null && photoPath.isNotEmpty) {
        updateValues['photo_path'] = photoPath;
      }
      await txn.update(
        DatabaseHelper.tableGrowthLogs,
        updateValues,
        where: 'id = ?',
        whereArgs: [logId],
      );

      // Check if this log is the most recent log for this plant
      final latest = await txn.query(
        DatabaseHelper.tableGrowthLogs,
        where: 'user_plant_id = ?',
        whereArgs: [userPlantId],
        orderBy: 'logged_at DESC',
        limit: 1,
      );

      if (latest.isNotEmpty && latest.first['id'] == logId) {
        if (photoPath != null && photoPath.isNotEmpty) {
          await txn.update(
            DatabaseHelper.tableUserPlants,
            {'cover_photo_path': photoPath},
            where: 'id = ?',
            whereArgs: [userPlantId],
          );
        }
      }
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

    // Prevent duplicate completion on the same day
    final existing = await db.query(
      DatabaseHelper.tableCareActionLogs,
      where: 'user_plant_id = ? AND task_type = ? AND log_date = ?',
      whereArgs: [userPlantId, taskType, logDate],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return;
    }

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

      // 3. Query interval_days and update care schedule
      final schedRows = await txn.query(
        DatabaseHelper.tableCareSchedules,
        where: 'user_plant_id = ? AND task_type = ?',
        whereArgs: [userPlantId, taskType],
      );

      final intervalDays = schedRows.isNotEmpty
          ? (schedRows.first['interval_days'] as int? ??
              (taskType == 'bersih_bersih' ? 7 : 1))
          : (taskType == 'bersih_bersih' ? 7 : 1);

      await txn.update(
        DatabaseHelper.tableCareSchedules,
        {
          'last_performed_at': now.toIso8601String(),
          'next_due_date':
              now.add(Duration(days: intervalDays)).toIso8601String(),
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

    // Prevent duplicate watering on the same day
    final existing = await db.query(
      DatabaseHelper.tableCareActionLogs,
      where: 'user_plant_id = ? AND task_type = ? AND log_date = ?',
      whereArgs: [userPlantId, 'siram', logDate],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return;
    }

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

  /// Returns the total XP accumulated by a user across all their plants and care logs in SQLite.
  Future<int> getTotalUserXp([String? userId]) async {
    final db = await _dbHelper.database;
    final parsedUserId = int.tryParse(userId ?? '1') ?? 1;

    // 1. Sum XP from user_plants
    final plantXpResult = await db.rawQuery('''
      SELECT COALESCE(SUM(xp), 0) as total_xp
      FROM ${DatabaseHelper.tableUserPlants}
      WHERE (user_id = ? OR CAST(user_id AS TEXT) = ?)
    ''', [parsedUserId, userId ?? '1']);
    final plantXp = Sqflite.firstIntValue(plantXpResult) ?? 0;

    // 2. Sum XP from care_action_logs
    final logXpResult = await db.rawQuery('''
      SELECT COALESCE(SUM(c.xp_awarded), 0) as total_xp
      FROM ${DatabaseHelper.tableCareActionLogs} c
      JOIN ${DatabaseHelper.tableUserPlants} p ON c.user_plant_id = p.id
      WHERE (p.user_id = ? OR CAST(p.user_id AS TEXT) = ?)
    ''', [parsedUserId, userId ?? '1']);
    final logXp = Sqflite.firstIntValue(logXpResult) ?? 0;

    return plantXp > logXp ? plantXp : logXp;
  }

  /// Checks if all active plants for a user have completed all daily tasks today.
  Future<bool> isAllTasksCompleteTodayForUser(String userId) async {
    final db = await _dbHelper.database;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final parsedUserId = int.tryParse(userId.toString()) ?? 1;

    // Get active plants
    var activePlants = await db.query(
      DatabaseHelper.tableUserPlants,
      columns: ['id'],
      where: '(user_id = ? OR CAST(user_id AS TEXT) = ?) AND is_archived = 0',
      whereArgs: [parsedUserId, userId.toString()],
    );

    if (activePlants.isEmpty && parsedUserId != 1) {
      activePlants = await db.query(
        DatabaseHelper.tableUserPlants,
        columns: ['id'],
        where: '(user_id = 1 OR CAST(user_id AS TEXT) = \'1\') AND is_archived = 0',
      );
    }

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

  /// Retrieves the most recent height recorded for a plant.
  Future<double> getLatestRecordedHeight(String userPlantId) async {
    final db = await _dbHelper.database;
    final growthRows = await db.query(
      DatabaseHelper.tableGrowthLogs,
      where: 'user_plant_id = ?',
      whereArgs: [userPlantId],
      orderBy: 'logged_at DESC',
      limit: 1,
    );

    if (growthRows.isNotEmpty) {
      return (growthRows.first['height_cm'] as num?)?.toDouble() ?? 30.0;
    }

    final plantRows = await db.query(
      DatabaseHelper.tableUserPlants,
      columns: ['initial_height_cm'],
      where: 'id = ?',
      whereArgs: [userPlantId],
      limit: 1,
    );

    if (plantRows.isNotEmpty) {
      return (plantRows.first['initial_height_cm'] as num?)?.toDouble() ?? 30.0;
    }

    return 30.0;
  }

  /// Checks if height has been logged today for a plant, returning the logged value if found.
  Future<double?> getLoggedHeightToday(String userPlantId) async {
    final db = await _dbHelper.database;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final growthRows = await db.query(
      DatabaseHelper.tableGrowthLogs,
      where: 'user_plant_id = ? AND substr(logged_at, 1, 10) = ? AND source = ?',
      whereArgs: [userPlantId, today, 'daily_task'],
      orderBy: 'logged_at DESC',
      limit: 1,
    );

    if (growthRows.isNotEmpty) {
      return (growthRows.first['height_cm'] as num?)?.toDouble();
    }
    return null;
  }

  /// Checks if a photo was logged today for a plant, returning the photo path if found.
  Future<String?> getLoggedPhotoToday(String userPlantId) async {
    final db = await _dbHelper.database;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final growthRows = await db.query(
      DatabaseHelper.tableGrowthLogs,
      columns: ['photo_path'],
      where: 'user_plant_id = ? AND substr(logged_at, 1, 10) = ? AND source = ? AND photo_path IS NOT NULL AND photo_path != \'\'',
      whereArgs: [userPlantId, today, 'daily_task'],
      orderBy: 'logged_at DESC',
      limit: 1,
    );

    if (growthRows.isNotEmpty) {
      return growthRows.first['photo_path'] as String?;
    }
    return null;
  }

  /// Returns the timestamp of the latest recorded photo for a plant.
  Future<DateTime?> getLatestPhotoDate(String userPlantId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableGrowthLogs,
      columns: ['logged_at'],
      where: 'user_plant_id = ? AND photo_path IS NOT NULL AND photo_path != \'\'',
      whereArgs: [userPlantId],
      orderBy: 'logged_at DESC',
      limit: 1,
    );

    if (rows.isNotEmpty) {
      return DateTime.tryParse(rows.first['logged_at'] as String);
    }
    return null;
  }

  /// Checks whether a photo update is due based on a periodic cycle (default: every 3 days).
  Future<bool> isPhotoDueForPlant(String userPlantId, {int cycleDays = 3}) async {
    final lastPhotoDate = await getLatestPhotoDate(userPlantId);
    if (lastPhotoDate == null) {
      return true; // No photo ever recorded -> photo is required on next log
    }

    final now = DateTime.now();
    final diffDays = DateTime(now.year, now.month, now.day)
        .difference(DateTime(lastPhotoDate.year, lastPhotoDate.month, lastPhotoDate.day))
        .inDays;

    return diffDays >= cycleDays;
  }

  /// Retrieves chronological care action history entries joined with plant nicknames and growth logs.
  Future<List<CareHistoryItem>> getCareHistory({
    String? userId,
    String? userPlantId,
  }) async {
    final db = await _dbHelper.database;

    String query = '''
      SELECT 
        c.id as log_id,
        c.user_plant_id,
        c.task_type,
        c.completed_at,
        c.log_date,
        c.xp_awarded,
        c.notes,
        p.nickname as plant_nickname,
        g.height_cm as logged_height,
        g.photo_path as logged_photo_path
      FROM ${DatabaseHelper.tableCareActionLogs} c
      LEFT JOIN ${DatabaseHelper.tableUserPlants} p ON c.user_plant_id = p.id
      LEFT JOIN ${DatabaseHelper.tableGrowthLogs} g ON g.user_plant_id = c.user_plant_id 
        AND substr(g.logged_at, 1, 10) = c.log_date 
        AND g.source = 'daily_task'
    ''';

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (userPlantId != null && userPlantId.isNotEmpty) {
      whereClauses.add('c.user_plant_id = ?');
      whereArgs.add(userPlantId);
    } else if (userId != null && userId.isNotEmpty && userId != 'usr_default') {
      final parsed = int.tryParse(userId);
      if (parsed != null) {
        whereClauses.add('(p.user_id = ? OR CAST(p.user_id AS TEXT) = ?)');
        whereArgs.addAll([parsed, userId]);
      }
    }

    if (whereClauses.isNotEmpty) {
      query += ' WHERE ${whereClauses.join(' AND ')}';
    }

    query += ' ORDER BY c.completed_at DESC';

    final results = await db.rawQuery(query, whereArgs);
    return results.map((row) => CareHistoryItem.fromMap(row)).toList();
  }
}
