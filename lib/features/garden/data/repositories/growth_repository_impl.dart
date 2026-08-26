import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/features/garden/domain/models/growth_log_model.dart';
import 'package:plenty/features/garden/domain/models/time_capsule_model.dart';
import 'package:plenty/features/garden/domain/repositories/growth_repository.dart';
import 'package:sqflite/sqflite.dart';

/// Repository implementation managing historical plant growth records, photo timelines, and time capsules.
class GrowthRepositoryImpl implements IGrowthRepository {
  final DatabaseHelper _dbHelper;

  GrowthRepositoryImpl({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<Result<List<GrowthLogModel>>> getHeightSeries(
    String userPlantId,
  ) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        DatabaseHelper.tableGrowthLogs,
        where: 'user_plant_id = ? AND height_cm IS NOT NULL',
        whereArgs: [userPlantId],
        orderBy: 'logged_at ASC',
      );

      final series = maps.map((m) => GrowthLogModel.fromMap(m)).toList();
      return Success(series);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<GrowthLogModel>>> getPhotoGallery(
    String userPlantId,
  ) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        DatabaseHelper.tableGrowthLogs,
        where: 'user_plant_id = ?',
        whereArgs: [userPlantId],
        orderBy: 'logged_at DESC',
      );

      final photos = maps.map((m) => GrowthLogModel.fromMap(m)).toList();
      return Success(photos);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<TimeCapsuleState>> getTimeCapsuleState(
    String userPlantId,
  ) async {
    try {
      final capsuleResult = await getTimeCapsule(userPlantId);
      final capsule = capsuleResult.dataOrNull;
      if (capsule == null) return const Success(TimeCapsuleState.none);
      if (capsule.isUnlocked || DateTime.now().isAfter(capsule.unlockAt)) {
        return const Success(TimeCapsuleState.unlocked);
      }
      return const Success(TimeCapsuleState.locked);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<TimeCapsuleModel?>> getTimeCapsule(String userPlantId) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        DatabaseHelper.tableTimeCapsules,
        where: 'user_plant_id = ?',
        whereArgs: [userPlantId],
        orderBy: 'created_at DESC',
        limit: 1,
      );

      if (maps.isEmpty) return const Success(null);
      return Success(TimeCapsuleModel.fromMap(maps.first));
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<bool>> saveTimeCapsule(
    TimeCapsuleModel capsule, {
    int userId = 1,
  }) async {
    try {
      final db = await _dbHelper.database;
      bool isFirstTimeCapsule = false;

      await db.transaction((txn) async {
        await txn.insert(
          DatabaseHelper.tableTimeCapsules,
          capsule.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        int effectiveUserId = userId;
        final plantRows = await txn.query(
          DatabaseHelper.tableUserPlants,
          columns: ['user_id'],
          where: 'id = ?',
          whereArgs: [capsule.userPlantId],
          limit: 1,
        );
        if (plantRows.isNotEmpty) {
          effectiveUserId =
              int.tryParse(plantRows.first['user_id']?.toString() ?? '') ??
              userId;
        }

        final userBadgeRows = await txn.query(
          DatabaseHelper.tableUserBadges,
          where: 'user_id = ? AND badge_id = ?',
          whereArgs: [effectiveUserId, 'time_capsule'],
        );

        final bool badgeAlreadyUnlocked =
            userBadgeRows.isNotEmpty &&
            ((userBadgeRows.first['is_unlocked'] as int?) == 1 ||
                userBadgeRows.first['unlocked_at'] != null);

        if (!badgeAlreadyUnlocked) {
          isFirstTimeCapsule = true;
          final now = DateTime.now();
          const months = [
            'Januari',
            'Februari',
            'Maret',
            'April',
            'Mei',
            'Juni',
            'Juli',
            'Agustus',
            'September',
            'Oktober',
            'November',
            'Desember',
          ];
          final formattedDate =
              '${now.day} ${months[now.month - 1]} ${now.year}';
          if (userBadgeRows.isNotEmpty) {
            await txn.update(
              DatabaseHelper.tableUserBadges,
              {
                'is_unlocked': 1,
                'current_progress': 1,
                'unlocked_at': formattedDate,
              },
              where: 'user_id = ? AND badge_id = ?',
              whereArgs: [effectiveUserId, 'time_capsule'],
            );
          } else {
            await txn.insert(
              DatabaseHelper.tableUserBadges,
              {
                'id': 'ub_${effectiveUserId}_time_capsule',
                'user_id': effectiveUserId,
                'badge_id': 'time_capsule',
                'is_unlocked': 1,
                'current_progress': 1,
                'unlocked_at': formattedDate,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          final countResult = await txn.rawQuery(
            '''
            SELECT COUNT(DISTINCT badge_id) as count FROM ${DatabaseHelper.tableUserBadges}
            WHERE user_id = ? AND is_unlocked = 1
          ''',
            [effectiveUserId],
          );
          final count = (countResult.first['count'] as int?) ?? 1;
          await txn.update(
            DatabaseHelper.tableUsers,
            {'unlocked_badges_count': count},
            where: 'id = ?',
            whereArgs: [effectiveUserId],
          );
        }
      });

      return Success(isFirstTimeCapsule);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> unlockTimeCapsule(String capsuleId) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        DatabaseHelper.tableTimeCapsules,
        {'is_unlocked': 1, 'unlocked_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [capsuleId],
      );
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> addGrowthLog(GrowthLogModel log) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        DatabaseHelper.tableGrowthLogs,
        log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }
}
