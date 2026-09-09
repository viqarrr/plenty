import 'package:plenty/core/constants/xp_config.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/daily_care/domain/models/care_action_log_model.dart';
import 'package:plenty/features/daily_care/domain/models/care_history_item.dart';
import 'package:plenty/features/daily_care/domain/models/daily_care_state.dart';
import 'package:plenty/features/daily_care/domain/repositories/daily_care_repository.dart';
import 'package:plenty/features/garden/data/repositories/plant_repository_impl.dart';
import 'package:plenty/features/garden/data/repositories/streak_repository_impl.dart';
import 'package:plenty/features/garden/domain/models/growth_log_model.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';
import 'package:plenty/features/garden/domain/repositories/plant_repository.dart';
import 'package:plenty/features/garden/domain/repositories/streak_repository.dart';
import 'package:plenty/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:plenty/features/profile/domain/repositories/badge_repository.dart';
import 'package:sqflite/sqflite.dart';

/// Consolidated implementation of IDailyCareRepository.
class DailyCareRepositoryImpl implements IDailyCareRepository {
  final DatabaseHelper _dbHelper;
  final IPlantRepository _plantRepo;
  final IStreakRepository _streakRepo;
  final IBadgeRepository? _badgeRepo;
  final ProfileRemoteDataSource? _remoteDataSource;

  DailyCareRepositoryImpl({
    DatabaseHelper? dbHelper,
    IPlantRepository? plantRepo,
    IStreakRepository? streakRepo,
    IBadgeRepository? badgeRepo,
    ProfileRemoteDataSource? remoteDataSource,
  }) : _dbHelper = dbHelper ?? DatabaseHelper.instance,
       _plantRepo = plantRepo ?? PlantRepositoryImpl(dbHelper: dbHelper),
       _streakRepo = streakRepo ?? StreakRepositoryImpl(dbHelper: dbHelper),
       _badgeRepo = badgeRepo,
       _remoteDataSource = remoteDataSource;

  @override
  Future<Result<DailyCareState>> loadDailyCareData({
    String? explicitUserId,
  }) async {
    try {
      final user = await PreferenceHandler.getUser();
      final userId =
          explicitUserId ??
          ((user?.id != null && user!.id!.isNotEmpty) ? user.id! : '1');

      final plantResult = await _plantRepo.getUserPlants(userId);
      final plants = plantResult.dataOrNull ?? [];

      final streakResult = await _streakRepo.getStreak(userId);
      final streak = streakResult.dataOrNull;

      final heightLogs = <DailyHeightLogItem>[];
      final dueSchedules = <DueScheduleItem>[];

      for (final plant in plants) {
        final lastHeightRes = await getLatestRecordedHeight(plant.id);
        final lastHeight = lastHeightRes.dataOrNull ?? 30.0;

        final loggedTodayRes = await getLoggedHeightToday(plant.id);
        final loggedToday = loggedTodayRes.dataOrNull;

        final isPhotoDue = await _isPhotoDueForPlant(plant.id, cycleDays: 3);
        final loggedPhotoTodayRes = await getLoggedPhotoToday(plant.id);
        final loggedPhotoToday = loggedPhotoTodayRes.dataOrNull;

        final loggedNoteTodayRes = await getLoggedNoteToday(plant.id);
        final loggedNoteToday = loggedNoteTodayRes.dataOrNull;

        heightLogs.add(
          DailyHeightLogItem(
            plant: plant,
            lastRecordedHeight: lastHeight,
            isCompletedToday: loggedToday != null,
            loggedHeightToday: loggedToday,
            isPhotoDue: isPhotoDue,
            loggedPhotoPathToday: loggedPhotoToday,
            loggedNoteToday: loggedNoteToday,
          ),
        );

        final dueTaskTypesRes = await getTodaysTaskTypes(plant.id);
        final dueTaskTypes = dueTaskTypesRes.dataOrNull ?? [];

        if (dueTaskTypes.contains('siram')) {
          dueSchedules.add(
            DueScheduleItem(
              plant: plant,
              taskType: 'siram',
              title: 'Penyiraman',
              subtitle: 'Siram 250ml air',
              isCompletedToday: false,
              xpAward: 10,
            ),
          );
        }

        if (dueTaskTypes.contains('bersih')) {
          dueSchedules.add(
            DueScheduleItem(
              plant: plant,
              taskType: 'bersih',
              title: 'Bersihkan Daun',
              subtitle: 'Bersihkan debu daun',
              isCompletedToday: false,
              xpAward: 10,
            ),
          );
        }
      }

      return Success(
        DailyCareState(
          heightLogs: heightLogs,
          dueSchedules: dueSchedules,
          streakCount: streak?.currentStreak ?? 0,
          isLoading: false,
        ),
      );
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> completeHeightTask({
    required PlantModel plant,
    required double heightCm,
    String? note,
    String? photoPath,
  }) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();
      final logDate = now.toIso8601String().substring(0, 10);
      final xpAwarded = XpConfig.xpPerTask['monitor'] ?? 15;

      final existing = await db.query(
        DatabaseHelper.tableCareActionLogs,
        where: 'user_plant_id = ? AND task_type = ? AND log_date = ?',
        whereArgs: [plant.id, 'monitor', logDate],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        return const Success(null);
      }

      await db.transaction((txn) async {
        final growthLog = GrowthLogModel(
          id: 'growth_${now.millisecondsSinceEpoch}',
          userPlantId: plant.id,
          photoPath: photoPath,
          heightCm: heightCm,
          leafCount: null,
          note: note,
          source: 'daily_task',
          loggedAt: now,
        );
        await txn.insert(DatabaseHelper.tableGrowthLogs, growthLog.toMap());

        final careLog = CareActionLogModel(
          id: 'care_log_${now.millisecondsSinceEpoch}_height',
          userPlantId: plant.id,
          taskType: 'monitor',
          completedAt: now,
          logDate: logDate,
          xpAwarded: xpAwarded,
          notes: note,
        );
        await txn.insert(DatabaseHelper.tableCareActionLogs, careLog.toMap());

        final plantRows = await txn.query(
          DatabaseHelper.tableUserPlants,
          where: 'id = ?',
          whereArgs: [plant.id],
        );

        if (plantRows.isNotEmpty) {
          final currentXp = (plantRows.first['xp'] as int? ?? 0);
          final newXp = currentXp + xpAwarded;
          final newLevel = XpConfig.levelForXp(newXp);
          final rawUserId = plantRows.first['user_id'];
          final parsedUserId = int.tryParse(rawUserId.toString()) ?? 1;

          final updateValues = <String, dynamic>{
            'xp': newXp,
            'level': newLevel,
            'initial_height_cm': heightCm,
            'current_height': heightCm,
            'initial_height': heightCm,
          };
          if (photoPath != null && photoPath.isNotEmpty) {
            updateValues['cover_photo_path'] = photoPath;
          }

          await txn.update(
            DatabaseHelper.tableUserPlants,
            updateValues,
            where: 'id = ?',
            whereArgs: [plant.id],
          );

          final activeUser = await PreferenceHandler.getUser();
          int? numId = parsedUserId ?? activeUser?.numericId;
          if (activeUser?.email != null && activeUser!.email.isNotEmpty) {
            final uRows = await txn.query(
              DatabaseHelper.tableUsers,
              columns: ['id'],
              where: 'email = ?',
              whereArgs: [activeUser.email],
              limit: 1,
            );
            if (uRows.isNotEmpty) {
              numId = uRows.first['id'] as int;
            }
          }
          if (numId != null) {
            final userRows = await txn.query(
              DatabaseHelper.tableUsers,
              where: 'id = ?',
              whereArgs: [numId],
              limit: 1,
            );
            if (userRows.isNotEmpty) {
              final currentUserXp = (userRows.first['total_xp'] as int? ?? 0);
              final newUserXp = currentUserXp + xpAwarded;
              final newUserLevel = XpConfig.levelForXp(newUserXp);
              await txn.update(
                DatabaseHelper.tableUsers,
                {'total_xp': newUserXp, 'level': newUserLevel},
                where: 'id = ?',
                whereArgs: [numId],
              );
            }
          }
        }

        await txn.update(
          DatabaseHelper.tableCareSchedules,
          {
            'last_performed_at': now.toIso8601String(),
            'next_due_date': now.add(const Duration(days: 1)).toIso8601String(),
          },
          where: 'user_plant_id = ? AND task_type = ?',
          whereArgs: [plant.id, 'monitor'],
        );
      });

      await _syncUserXpAndBadges(rawUserId: plant.userId);
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateHeightTask({
    required PlantModel plant,
    required double heightCm,
    String? note,
    String? photoPath,
  }) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();
      final logDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await db.transaction((txn) async {
        final existingLogs = await txn.query(
          DatabaseHelper.tableGrowthLogs,
          where: 'user_plant_id = ? AND logged_at LIKE ?',
          whereArgs: [plant.id, '$logDate%'],
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

        await txn.update(
          DatabaseHelper.tableCareActionLogs,
          {'notes': note, 'completed_at': now.toIso8601String()},
          where: 'user_plant_id = ? AND task_type = ? AND log_date = ?',
          whereArgs: [plant.id, 'monitor', logDate],
        );

        final plantUpdate = <String, dynamic>{
          'initial_height_cm': heightCm,
          'current_height': heightCm,
          'initial_height': heightCm,
        };
        if (photoPath != null && photoPath.isNotEmpty) {
          plantUpdate['cover_photo_path'] = photoPath;
        }
        await txn.update(
          DatabaseHelper.tableUserPlants,
          plantUpdate,
          where: 'id = ?',
          whereArgs: [plant.id],
        );
      });
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> completeRoutineTask({
    required PlantModel plant,
    required String taskType,
    String? notes,
  }) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();
      final logDate = now.toIso8601String().substring(0, 10);
      final xpAwarded = XpConfig.xpPerTask[taskType] ?? 10;

      final existing = await db.query(
        DatabaseHelper.tableCareActionLogs,
        where: 'user_plant_id = ? AND task_type = ? AND log_date = ?',
        whereArgs: [plant.id, taskType, logDate],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        return const Success(null);
      }

      await db.transaction((txn) async {
        final careLog = CareActionLogModel(
          id: 'care_log_${now.millisecondsSinceEpoch}_$taskType',
          userPlantId: plant.id,
          taskType: taskType,
          completedAt: now,
          logDate: logDate,
          xpAwarded: xpAwarded,
          notes: notes,
        );
        await txn.insert(DatabaseHelper.tableCareActionLogs, careLog.toMap());

        final plantRows = await txn.query(
          DatabaseHelper.tableUserPlants,
          where: 'id = ?',
          whereArgs: [plant.id],
        );

        if (plantRows.isNotEmpty) {
          final currentXp = (plantRows.first['xp'] as int? ?? 0);
          final newXp = currentXp + xpAwarded;
          final newLevel = XpConfig.levelForXp(newXp);
          final rawUserId = plantRows.first['user_id'];
          final parsedUserId = int.tryParse(rawUserId.toString()) ?? 1;

          await txn.update(
            DatabaseHelper.tableUserPlants,
            {'xp': newXp, 'level': newLevel},
            where: 'id = ?',
            whereArgs: [plant.id],
          );

          final activeUser = await PreferenceHandler.getUser();
          int? numId = parsedUserId;
          if (activeUser?.email != null && activeUser!.email.isNotEmpty) {
            final uRows = await txn.query(
              DatabaseHelper.tableUsers,
              columns: ['id'],
              where: 'email = ?',
              whereArgs: [activeUser.email],
              limit: 1,
            );
            if (uRows.isNotEmpty) {
              numId = uRows.first['id'] as int;
            }
          }
          if (numId != null) {
            final userRows = await txn.query(
              DatabaseHelper.tableUsers,
              where: 'id = ?',
              whereArgs: [numId],
              limit: 1,
            );
            if (userRows.isNotEmpty) {
              final currentUserXp = (userRows.first['total_xp'] as int? ?? 0);
              final newUserXp = currentUserXp + xpAwarded;
              final newUserLevel = XpConfig.levelForXp(newUserXp);
              await txn.update(
                DatabaseHelper.tableUsers,
                {'total_xp': newUserXp, 'level': newUserLevel},
                where: 'id = ?',
                whereArgs: [numId],
              );
            }
          }
        }

        final schedRows = await txn.query(
          DatabaseHelper.tableCareSchedules,
          where: 'user_plant_id = ? AND task_type = ?',
          whereArgs: [plant.id, taskType],
        );

        final intervalDays = schedRows.isNotEmpty
            ? (schedRows.first['interval_days'] as int? ??
                  (taskType == 'bersih' ? 7 : (taskType == 'siram' ? 3 : 1)))
            : (taskType == 'bersih' ? 7 : (taskType == 'siram' ? 3 : 1));

        await txn.update(
          DatabaseHelper.tableCareSchedules,
          {
            'last_performed_at': now.toIso8601String(),
            'next_due_date': now
                .add(Duration(days: intervalDays))
                .toIso8601String(),
          },
          where: 'user_plant_id = ? AND task_type = ?',
          whereArgs: [plant.id, taskType],
        );
      });

      await _syncUserXpAndBadges(rawUserId: plant.userId);
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> completeCyclicTask(DueScheduleItem item) {
    return completeRoutineTask(plant: item.plant, taskType: item.taskType);
  }

  @override
  Future<Result<List<CareHistoryItem>>> getCareHistory({
    String? userId,
    String? userPlantId,
  }) async {
    try {
      final db = await _dbHelper.database;
      String query =
          '''
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
      } else if (userId != null && userId.isNotEmpty) {
        final parsed = int.tryParse(userId);
        whereClauses.add('(p.user_id = ? OR CAST(p.user_id AS TEXT) = ?)');
        whereArgs.addAll([parsed ?? userId, userId]);
      }

      if (whereClauses.isNotEmpty) {
        query += ' WHERE ${whereClauses.join(' AND ')}';
      }

      query += ' ORDER BY c.completed_at DESC';

      final results = await db.rawQuery(query, whereArgs);
      final items = results.map((row) => CareHistoryItem.fromMap(row)).toList();
      return Success(items);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<String>>> getTodaysTaskTypes(String userPlantId) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();
      final today = now.toIso8601String().substring(0, 10);

      final completedRows = await db.query(
        DatabaseHelper.tableCareActionLogs,
        columns: ['task_type'],
        where: 'user_plant_id = ? AND log_date = ?',
        whereArgs: [userPlantId, today],
      );
      final completedTypes = completedRows
          .map((r) => r['task_type'] as String)
          .toSet();

      final tasks = <String>[];

      if (!completedTypes.contains('monitor')) {
        tasks.add('monitor');
      }

      final cyclicTaskTypes = ['siram', 'bersih'];
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
              final isDueOrPast =
                  nextDue.isBefore(now) ||
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

      return Success(tasks);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<double>> getLatestRecordedHeight(String userPlantId) async {
    try {
      final db = await _dbHelper.database;
      final growthRows = await db.query(
        DatabaseHelper.tableGrowthLogs,
        where: 'user_plant_id = ?',
        whereArgs: [userPlantId],
        orderBy: 'logged_at DESC',
        limit: 1,
      );

      if (growthRows.isNotEmpty) {
        final height =
            (growthRows.first['height_cm'] as num?)?.toDouble() ?? 30.0;
        return Success(height);
      }

      final plantRows = await db.query(
        DatabaseHelper.tableUserPlants,
        columns: ['initial_height_cm'],
        where: 'id = ?',
        whereArgs: [userPlantId],
        limit: 1,
      );

      if (plantRows.isNotEmpty) {
        final height =
            (plantRows.first['initial_height_cm'] as num?)?.toDouble() ?? 30.0;
        return Success(height);
      }

      return const Success(30.0);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<double?>> getLoggedHeightToday(String userPlantId) async {
    try {
      final db = await _dbHelper.database;
      final today = DateTime.now().toIso8601String().substring(0, 10);

      final growthRows = await db.query(
        DatabaseHelper.tableGrowthLogs,
        where:
            'user_plant_id = ? AND substr(logged_at, 1, 10) = ? AND source = ?',
        whereArgs: [userPlantId, today, 'daily_task'],
        orderBy: 'logged_at DESC',
        limit: 1,
      );

      if (growthRows.isNotEmpty) {
        return Success((growthRows.first['height_cm'] as num?)?.toDouble());
      }
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<String?>> getLoggedPhotoToday(String userPlantId) async {
    try {
      final db = await _dbHelper.database;
      final today = DateTime.now().toIso8601String().substring(0, 10);

      final growthRows = await db.query(
        DatabaseHelper.tableGrowthLogs,
        columns: ['photo_path'],
        where:
            'user_plant_id = ? AND substr(logged_at, 1, 10) = ? AND source = ? AND photo_path IS NOT NULL AND photo_path != \'\'',
        whereArgs: [userPlantId, today, 'daily_task'],
        orderBy: 'logged_at DESC',
        limit: 1,
      );

      if (growthRows.isNotEmpty) {
        return Success(growthRows.first['photo_path'] as String?);
      }
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<String?>> getLoggedNoteToday(String userPlantId) async {
    try {
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
      if (rows.isEmpty) return const Success(null);
      return Success(rows.first['note'] as String?);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  Future<bool> _isPhotoDueForPlant(
    String userPlantId, {
    int cycleDays = 3,
  }) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableGrowthLogs,
      columns: ['logged_at'],
      where:
          'user_plant_id = ? AND photo_path IS NOT NULL AND photo_path != \'\'',
      whereArgs: [userPlantId],
      orderBy: 'logged_at DESC',
      limit: 1,
    );

    if (rows.isEmpty) return true;
    final lastPhotoDate = DateTime.tryParse(rows.first['logged_at'] as String);
    if (lastPhotoDate == null) return true;

    final now = DateTime.now();
    final diffDays = DateTime(now.year, now.month, now.day)
        .difference(
          DateTime(lastPhotoDate.year, lastPhotoDate.month, lastPhotoDate.day),
        )
        .inDays;

    return diffDays >= cycleDays;
  }

  @override
  Future<Result<int>> getTotalUserXp([String? userId]) async {
    try {
      final db = await _dbHelper.database;
      final activeUser = await PreferenceHandler.getUser();
      final effectiveUserId = (userId != null &&
              userId.isNotEmpty &&
              userId != '1' &&
              userId != 'usr_default')
          ? userId
          : (activeUser?.id ?? userId ?? '1');
      final parsedUserId = int.tryParse(effectiveUserId) ?? (activeUser?.numericId ?? 1);

      final plantXpResult = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(xp), 0) as total_xp
        FROM ${DatabaseHelper.tableUserPlants}
        WHERE (user_id = ? OR CAST(user_id AS TEXT) = ? OR user_id = ? OR user_id = 'usr_default')
      ''',
        [parsedUserId, effectiveUserId, activeUser?.id ?? ''],
      );
      final plantXp = Sqflite.firstIntValue(plantXpResult) ?? 0;

      final logXpResult = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(c.xp_awarded), 0) as total_xp
        FROM ${DatabaseHelper.tableCareActionLogs} c
        JOIN ${DatabaseHelper.tableUserPlants} p ON c.user_plant_id = p.id
        WHERE (p.user_id = ? OR CAST(p.user_id AS TEXT) = ? OR p.user_id = ? OR p.user_id = 'usr_default')
      ''',
        [parsedUserId, effectiveUserId, activeUser?.id ?? ''],
      );
      final logXp = Sqflite.firstIntValue(logXpResult) ?? 0;

      int userTableXp = 0;
      try {
        final uRows = await db.rawQuery(
          '''
          SELECT total_xp FROM ${DatabaseHelper.tableUsers}
          WHERE id = ? OR email = ? OR id = ?
          ''',
          [parsedUserId, activeUser?.email ?? '', activeUser?.numericId ?? 0],
        );
        if (uRows.isNotEmpty) {
          userTableXp = (uRows.first['total_xp'] as int?) ?? 0;
        }
      } catch (_) {}

      final sessionXp = activeUser?.totalXp ?? 0;
      final result = [plantXp, logXp, userTableXp, sessionXp]
          .reduce((a, b) => a > b ? a : b);
      return Success(result);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<bool>> isAllTasksCompleteTodayForUser(String userId) async {
    try {
      final db = await _dbHelper.database;
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final parsedUserId = int.tryParse(userId.toString());

      final activePlants = await db.query(
        DatabaseHelper.tableUserPlants,
        columns: ['id'],
        where: "(user_id = ? OR CAST(user_id AS TEXT) = ? OR user_id = ? OR user_id = 'usr_default') AND is_archived = 0",
        whereArgs: [parsedUserId ?? userId, userId.toString(), userId],
      );

      if (activePlants.isEmpty) return const Success(false);

      // Verify that the user has performed at least one care action today
      final totalTodayLogs = await db.query(
        DatabaseHelper.tableCareActionLogs,
        where: 'log_date = ?',
        whereArgs: [today],
      );
      if (totalTodayLogs.isEmpty) {
        return const Success(false);
      }

      for (final plantMap in activePlants) {
        final plantId = plantMap['id'] as String;
        final requiredTaskTypesRes = await getTodaysTaskTypes(plantId);
        final requiredTaskTypes = requiredTaskTypesRes.dataOrNull ?? [];
        if (requiredTaskTypes.isNotEmpty) {
          return const Success(false);
        }
      }

      return const Success(true);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateGrowthLog({
    required String logId,
    required String userPlantId,
    required double heightCm,
    String? note,
    String? photoPath,
  }) async {
    try {
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

        final latest = await txn.query(
          DatabaseHelper.tableGrowthLogs,
          where: 'user_plant_id = ?',
          whereArgs: [userPlantId],
          orderBy: 'logged_at DESC',
          limit: 1,
        );

        if (latest.isNotEmpty && latest.first['id'] == logId) {
          final plantUpdate = <String, dynamic>{
            'initial_height_cm': heightCm,
            'current_height': heightCm,
            'initial_height': heightCm,
          };
          if (photoPath != null && photoPath.isNotEmpty) {
            plantUpdate['cover_photo_path'] = photoPath;
          }
          await txn.update(
            DatabaseHelper.tableUserPlants,
            plantUpdate,
            where: 'id = ?',
            whereArgs: [userPlantId],
          );
        }
      });
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  Future<void> _syncUserXpAndBadges({
    required String rawUserId,
  }) async {
    try {
      final activeUser = await PreferenceHandler.getUser();
      final stringUserId = (rawUserId.isNotEmpty &&
              rawUserId != '1' &&
              rawUserId != '0' &&
              rawUserId != 'usr_default')
          ? rawUserId
          : (activeUser?.id ?? '1');

      // 1. Compute the new total user XP from plants and care action logs
      final totalXpRes = await getTotalUserXp(stringUserId);
      final computedXp = totalXpRes.dataOrNull ?? 0;
      final newLevel = XpConfig.levelForXp(computedXp);

      // 2. Update SQLite users table for active user
      final db = await _dbHelper.database;
      int? targetNumId = activeUser?.numericId ?? int.tryParse(stringUserId);
      if (targetNumId == null && activeUser?.email != null) {
        final userRows = await db.query(
          DatabaseHelper.tableUsers,
          columns: ['id'],
          where: 'email = ?',
          whereArgs: [activeUser!.email],
          limit: 1,
        );
        if (userRows.isNotEmpty) {
          targetNumId = userRows.first['id'] as int;
        }
      }
      if (targetNumId != null) {
        await db.update(
          DatabaseHelper.tableUsers,
          {'total_xp': computedXp, 'level': newLevel},
          where: 'id = ?',
          whereArgs: [targetNumId],
        );
      }

      // 3. Update Cloud Firestore
      if (stringUserId.isNotEmpty &&
          stringUserId != '1' &&
          stringUserId != 'usr_default') {
        await _remoteDataSource?.updateUserXpAndLevel(
          stringUserId,
          totalXp: computedXp,
          level: newLevel,
        );
      }

      // 4. Update local session cache (PreferenceHandler)
      if (activeUser != null) {
        await PreferenceHandler.setUser(activeUser.copyWith(
          totalXp: computedXp,
          level: newLevel,
        ));
      }

      // 5. Evaluate daily streak ONLY when all tasks for today are completed
      final allDoneRes = await isAllTasksCompleteTodayForUser(stringUserId);
      if (allDoneRes.dataOrNull == true) {
        await _streakRepo.evaluateDailyStreak(stringUserId);
      }
    } catch (_) {}
  }
}
