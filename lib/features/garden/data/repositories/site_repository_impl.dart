import 'package:plenty/core/constants/site_icons.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/auth/domain/models/user_model.dart';
import 'package:plenty/features/garden/data/datasources/garden_remote_datasource.dart';
import 'package:plenty/features/garden/domain/models/site_model.dart';
import 'package:plenty/features/garden/domain/repositories/site_repository.dart';
import 'package:sqflite/sqflite.dart';

/// Repository implementation managing persistence of default and custom user plant placement locations.
class SiteRepositoryImpl implements ISiteRepository {
  final DatabaseHelper _dbHelper;
  final GardenRemoteDataSource? _remoteDataSource;

  SiteRepositoryImpl({
    DatabaseHelper? dbHelper,
    GardenRemoteDataSource? remoteDataSource,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _remoteDataSource = remoteDataSource;

  @override
  Future<Result<List<SiteModel>>> getSites([String userId = '1']) async {
    try {
      final db = await _dbHelper.database;
      UserModel? activeUser;
      try {
        activeUser = await PreferenceHandler.getUser();
      } catch (_) {}

      final effectiveUserId =
          (userId.isNotEmpty && userId != '1' && userId != 'usr_default')
              ? userId
              : ((activeUser?.id != null &&
                      activeUser!.id!.isNotEmpty &&
                      activeUser.id != '0')
                  ? activeUser.id!
                  : (userId.isNotEmpty ? userId : '1'));

      final intUserId =
          int.tryParse(effectiveUserId) ?? (activeUser?.numericId ?? 1);

      // Cloud-first sync from Firestore if remote data source is available
      if (_remoteDataSource != null &&
          effectiveUserId.isNotEmpty &&
          effectiveUserId != 'usr_default') {
        try {
          final remoteSites = await _remoteDataSource.getSites(effectiveUserId);
          for (final site in remoteSites) {
            final payload = site.toMap()..['is_custom'] = 1;
            await db.insert(
              DatabaseHelper.tableSites,
              payload,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        } catch (_) {
          // Graceful fallback to local cache
        }
      }

      final maps = await db.query(
        DatabaseHelper.tableSites,
        where: 'user_id = ? OR is_custom = 0',
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
      UserModel? activeUser;
      try {
        activeUser = await PreferenceHandler.getUser();
      } catch (_) {}

      final effectiveUserId = (site.userId.isNotEmpty &&
              site.userId != '1' &&
              site.userId != 'usr_default')
          ? site.userId
          : ((activeUser?.id != null &&
                  activeUser!.id!.isNotEmpty &&
                  activeUser.id != '0')
              ? activeUser.id!
              : site.userId);

      final customSite =
          site.copyWith(userId: effectiveUserId, isCustom: true);
      final payload = customSite.toMap()..['is_custom'] = 1;

      await db.insert(
        DatabaseHelper.tableSites,
        payload,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (_remoteDataSource != null &&
          effectiveUserId.isNotEmpty &&
          effectiveUserId != 'usr_default') {
        try {
          await _remoteDataSource.saveSite(customSite);
        } catch (_) {
          // Offline resilience: local write succeeded
        }
      }

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
      final customSite = site.copyWith(isCustom: true);
      final payload = customSite.toMap()..['is_custom'] = 1;
      await db.update(
        DatabaseHelper.tableSites,
        payload,
        where: 'id = ? AND is_custom = 1',
        whereArgs: [site.id],
      );

      if (_remoteDataSource != null) {
        try {
          await _remoteDataSource.updateSite(customSite);
        } catch (_) {}
      }

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

      if (_remoteDataSource != null) {
        try {
          await _remoteDataSource.deleteSite(siteId);
        } catch (_) {}
      }

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
