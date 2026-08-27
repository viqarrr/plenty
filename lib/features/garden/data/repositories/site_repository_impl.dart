import 'package:plenty/core/constants/site_icons.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/features/garden/domain/models/site_model.dart';
import 'package:plenty/features/garden/domain/repositories/site_repository.dart';
import 'package:sqflite/sqflite.dart';

/// Repository implementation managing persistence of default and custom user plant placement locations.
class SiteRepositoryImpl implements ISiteRepository {
  final DatabaseHelper _dbHelper;

  SiteRepositoryImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<Result<List<SiteModel>>> getSites([String userId = '1']) async {
    try {
      final db = await _dbHelper.database;
      final intUserId = int.tryParse(userId) ?? 1;

      final maps = await db.query(
        DatabaseHelper.tableSites,
        where: 'user_id = ?',
        whereArgs: [intUserId],
        orderBy: 'is_custom ASC, created_at ASC',
      );

      final sites = maps.map((map) => SiteModel.fromMap(map)).toList();
      return Success(sites);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> addCustomSite(SiteModel site) async {
    try {
      final db = await _dbHelper.database;
      final payload = site.toMap()..['is_custom'] = 1;
      await db.insert(
        DatabaseHelper.tableSites,
        payload,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateCustomSite(SiteModel site) async {
    try {
      final guard = await _assertIsCustomEditable(site.id);
      if (guard != null) return Error(guard);

      final db = await _dbHelper.database;
      final payload = site.toMap()..['is_custom'] = 1;
      await db.update(
        DatabaseHelper.tableSites,
        payload,
        where: 'id = ? AND is_custom = 1',
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
      final guard = await _assertIsCustomEditable(siteId);
      if (guard != null) return Error(guard);

      final db = await _dbHelper.database;

      await db.transaction((txn) async {
        // Product decision: Plants referring to a deleted site should not lose location context.
        // Reassign affected plants to the default living room site.
        await txn.update(
          DatabaseHelper.tableUserPlants,
          {'site_id': SiteIcons.defaultLivingRoomId},
          where: 'site_id = ?',
          whereArgs: [siteId],
        );

        await txn.delete(
          DatabaseHelper.tableSites,
          where: 'id = ? AND is_custom = 1',
          whereArgs: [siteId],
        );
      });

      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  /// Returns a [Failure] if the site does not exist or is a non-editable default site.
  Future<Failure?> _assertIsCustomEditable(String siteId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableSites,
      where: 'id = ?',
      whereArgs: [siteId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return const ValidationFailure('Site tidak ditemukan.');
    }
    final isCustom = (rows.first['is_custom'] as int?) == 1;
    if (!isCustom) {
      return const ValidationFailure(
        'Site bawaan aplikasi tidak dapat diubah atau dihapus.',
      );
    }
    return null;
  }
}
