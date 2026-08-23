import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/domain/models/growth_log_model.dart';
import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/features/garden/domain/models/time_capsule_model.dart';
import 'package:plenty/features/garden/domain/repositories/growth_repository.dart';
import 'package:sqflite/sqflite.dart';

/// Repository implementation managing historical plant growth records, photo timelines, and time capsules.
class GrowthRepositoryImpl implements IGrowthRepository {
  final DatabaseHelper _dbHelper;

  GrowthRepositoryImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<Result<List<GrowthLogModel>>> getHeightSeries(String userPlantId) async {
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
  Future<Result<List<GrowthLogModel>>> getPhotoGallery(String userPlantId) async {
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
  Future<Result<TimeCapsuleState>> getTimeCapsuleState(String userPlantId) async {
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
  Future<Result<void>> saveTimeCapsule(TimeCapsuleModel capsule) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        DatabaseHelper.tableTimeCapsules,
        capsule.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Success(null);
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
        {
          'is_unlocked': 1,
          'unlocked_at': DateTime.now().toIso8601String(),
        },
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
