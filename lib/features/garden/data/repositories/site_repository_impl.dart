import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/features/garden/domain/models/custom_site_model.dart';
import 'package:plenty/features/garden/domain/repositories/site_repository.dart';
import 'package:sqflite/sqflite.dart';

/// Repository implementation managing persistence of custom user plant placement locations.
class SiteRepositoryImpl implements ISiteRepository {
  final DatabaseHelper _dbHelper;

  SiteRepositoryImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<Result<List<CustomSiteModel>>> getCustomSites([String userId = '1']) async {
    try {
      final db = await _dbHelper.database;
      final intUserId = int.tryParse(userId) ?? 1;

      final maps = await db.query(
        DatabaseHelper.tableCustomSites,
        where: 'user_id = ?',
        whereArgs: [intUserId],
        orderBy: 'created_at ASC',
      );

      final sites = maps.map((map) => CustomSiteModel.fromMap(map)).toList();
      return Success(sites);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> saveCustomSite(CustomSiteModel site) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        DatabaseHelper.tableCustomSites,
        site.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateCustomSite(CustomSiteModel site) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        DatabaseHelper.tableCustomSites,
        site.toMap(),
        where: 'id = ?',
        whereArgs: [site.id],
      );
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteCustomSite(String siteId) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        DatabaseHelper.tableCustomSites,
        where: 'id = ?',
        whereArgs: [siteId],
      );
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }
}
