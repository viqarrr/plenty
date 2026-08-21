import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/features/garden/domain/models/custom_site_model.dart';
import 'package:sqflite/sqflite.dart';

/// Repository managing persistence of custom user plant placement locations (sites/rooms).
class SiteRepository {
  final DatabaseHelper _dbHelper;

  SiteRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  DatabaseHelper get dbHelper => _dbHelper;

  /// Retrieves all custom sites for the specified user ordered chronologically.
  Future<List<CustomSiteModel>> getCustomSites([String userId = '1']) async {
    final db = await _dbHelper.database;
    final intUserId = int.tryParse(userId) ?? 1;

    final maps = await db.query(
      DatabaseHelper.tableCustomSites,
      where: 'user_id = ?',
      whereArgs: [intUserId],
      orderBy: 'created_at ASC',
    );

    return maps.map((map) => CustomSiteModel.fromMap(map)).toList();
  }

  /// Inserts a new custom site record.
  Future<void> saveCustomSite(CustomSiteModel site) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseHelper.tableCustomSites,
      site.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Updates an existing custom site record.
  Future<void> updateCustomSite(CustomSiteModel site) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableCustomSites,
      site.toMap(),
      where: 'id = ?',
      whereArgs: [site.id],
    );
  }

  /// Deletes a custom site record by ID.
  Future<void> deleteCustomSite(String siteId) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableCustomSites,
      where: 'id = ?',
      whereArgs: [siteId],
    );
  }
}
