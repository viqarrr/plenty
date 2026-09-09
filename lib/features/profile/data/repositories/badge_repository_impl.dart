import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:plenty/features/profile/domain/models/badge_item.dart';
import 'package:plenty/features/profile/domain/repositories/badge_repository.dart';
import 'package:sqflite/sqflite.dart';

/// Implementation of IBadgeRepository combining Cloud Firestore and local SQLite caching.
class BadgeRepositoryImpl implements IBadgeRepository {
  final DatabaseHelper _dbHelper;
  final ProfileRemoteDataSource _remoteDataSource;

  BadgeRepositoryImpl({
    DatabaseHelper? dbHelper,
    ProfileRemoteDataSource? remoteDataSource,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _remoteDataSource =
            remoteDataSource ?? FirestoreProfileRemoteDataSourceImpl();

  Future<int> _resolveUserId(int? userId) async {
    if (userId != null && userId != 0) return userId;
    try {
      final activeUser = await PreferenceHandler.getUser();
      if (activeUser?.email != null && activeUser!.email.isNotEmpty) {
        final db = await _dbHelper.database;
        final rows = await db.query(
          DatabaseHelper.tableUsers,
          columns: ['id'],
          where: 'email = ?',
          whereArgs: [activeUser.email],
          limit: 1,
        );
        if (rows.isNotEmpty) {
          final foundId = rows.first['id'] as int;
          return foundId;
        }
      }
      if (activeUser != null &&
          activeUser.numericId != null &&
          activeUser.numericId != 0) {
        return activeUser.numericId!;
      }
    } catch (_) {}
    return 1;
  }

  @override
  Future<Result<List<BadgeItem>>> getBadges({int? userId}) async {
    try {
      final effectiveUserId = await _resolveUserId(userId);
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> rows = await db.rawQuery(
        '''
        SELECT 
          b.id,
          b.title,
          b.description,
          b.icon_name,
          b.tier_name,
          b.level,
          b.target_total,
          b.bg_color_hex,
          b.accent_color_hex,
          MAX(COALESCE(ub.is_unlocked, 0)) as is_unlocked,
          MAX(COALESCE(ub.current_progress, 0)) as current_progress,
          MAX(ub.unlocked_at) as unlocked_at
        FROM ${DatabaseHelper.tableBadges} b
        LEFT JOIN ${DatabaseHelper.tableUserBadges} ub 
          ON b.id = ub.badge_id AND ub.user_id = ?
        GROUP BY b.id, b.title, b.description, b.icon_name, b.tier_name, b.level, b.target_total, b.bg_color_hex, b.accent_color_hex
        ORDER BY b.rowid ASC
      ''',
        [effectiveUserId],
      );

      var badges = rows
          .map(_mapRowToBadgeItem)
          .where((b) => b.id != 'doctor_green' && b.id != 'sun_master')
          .toList();

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
      final formattedDate = '${now.day} ${months[now.month - 1]} ${now.year}';

      // Merge badges from Cloud Firestore if available
      try {
        final activeUser = await PreferenceHandler.getUser();
        final uid = (activeUser?.id != null && activeUser!.id!.isNotEmpty)
            ? activeUser.id!
            : (userId?.toString() ?? '1');
        if (uid.isNotEmpty && uid != '0' && uid != '1' && uid != 'usr_default') {
          final remoteBadges = await _remoteDataSource?.getUserBadges(uid);
          final remoteUnlockedMap = {
            if (remoteBadges != null)
              for (final b in remoteBadges)
                if (b['is_unlocked'] == true || b['is_unlocked'] == 1)
                  b['badge_id'] as String?: b,
          };

          badges = badges.map((badge) {
            final remote = remoteUnlockedMap[badge.id];
            if (remote != null && !badge.isUnlocked) {
              return badge.copyWith(
                isUnlocked: true,
                unlockedDate: remote['unlocked_at'] as String?,
                progress:
                    (remote['current_progress'] as num?)?.toInt() ?? badge.total,
              );
            }
            return badge;
          }).toList();

          // Push any locally unlocked badges to remote Firestore if missing remotely
          for (final b in badges) {
            if (b.isUnlocked && !remoteUnlockedMap.containsKey(b.id)) {
              try {
                await _remoteDataSource?.awardBadge(
                  uid,
                  b.id,
                  b.unlockedDate ?? formattedDate,
                );
              } catch (_) {}
            }
          }

          // Auto-check and backfill earned badges from existing local plants & streak
          final plantRows = await db.rawQuery(
            '''
            SELECT COUNT(*) as count FROM ${DatabaseHelper.tableUserPlants}
            WHERE (user_id = ? OR CAST(user_id AS TEXT) = ? OR user_id = 'usr_default') AND is_archived = 0
            ''',
            [effectiveUserId, uid],
          );
          final plantCount = (plantRows.first['count'] as int?) ?? 0;
          if (plantCount >= 1 && !badges.any((b) => b.id == 'first_plant' && b.isUnlocked)) {
            await awardBadge(userId: uid, badgeId: 'first_plant');
            badges = badges.map((b) => b.id == 'first_plant' ? b.copyWith(isUnlocked: true) : b).toList();
          }
          if (plantCount >= 5 && !badges.any((b) => b.id == 'plant_collector' && b.isUnlocked)) {
            await awardBadge(userId: uid, badgeId: 'plant_collector');
            badges = badges.map((b) => b.id == 'plant_collector' ? b.copyWith(isUnlocked: true) : b).toList();
          }

          final streakRows = await db.rawQuery(
            '''
            SELECT streak_count FROM ${DatabaseHelper.tableUsers}
            WHERE id = ? OR email = ?
            ''',
            [effectiveUserId, activeUser?.email ?? ''],
          );
          final streakVal = streakRows.isNotEmpty
              ? (streakRows.first['streak_count'] as int? ?? 0)
              : (activeUser?.streakCount ?? 0);
          if (streakVal >= 7 && !badges.any((b) => b.id == 'water_streak' && b.isUnlocked)) {
            await awardBadge(userId: uid, badgeId: 'water_streak');
            badges = badges.map((b) => b.id == 'water_streak' ? b.copyWith(isUnlocked: true) : b).toList();
          }
        }
      } catch (_) {}

      return Success(badges);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<BadgeItem>>> getUnlockedBadges({int? userId}) async {
    try {
      final allBadgesResult = await getBadges(userId: userId);
      final allBadges = allBadgesResult.dataOrNull ?? [];
      return Success(allBadges.where((b) => b.isUnlocked).toList());
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<int>> getUnlockedBadgeCount({int? userId}) async {
    try {
      final allBadgesResult = await getBadges(userId: userId);
      final allBadges = allBadgesResult.dataOrNull ?? [];
      return Success(allBadges.where((b) => b.isUnlocked).length);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<int>> getUserBadgeCount([dynamic userId]) =>
      getUnlockedBadgeCount(userId: int.tryParse(userId?.toString() ?? '1'));

  @override
  Future<Result<BadgeItem?>> getBadgeById(String badgeId, {int? userId}) async {
    try {
      final effectiveUserId = await _resolveUserId(userId);
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> rows = await db.rawQuery(
        '''
        SELECT 
          b.id,
          b.title,
          b.description,
          b.icon_name,
          b.tier_name,
          b.level,
          b.target_total,
          b.bg_color_hex,
          b.accent_color_hex,
          MAX(COALESCE(ub.is_unlocked, 0)) as is_unlocked,
          MAX(COALESCE(ub.current_progress, 0)) as current_progress,
          MAX(ub.unlocked_at) as unlocked_at
        FROM ${DatabaseHelper.tableBadges} b
        LEFT JOIN ${DatabaseHelper.tableUserBadges} ub 
          ON b.id = ub.badge_id AND ub.user_id = ?
        WHERE b.id = ?
        GROUP BY b.id, b.title, b.description, b.icon_name, b.tier_name, b.level, b.target_total, b.bg_color_hex, b.accent_color_hex
        LIMIT 1
      ''',
        [effectiveUserId, badgeId],
      );

      if (rows.isEmpty) return const Success(null);
      return Success(_mapRowToBadgeItem(rows.first));
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<bool>> awardBadge({
    required dynamic userId,
    required String badgeId,
  }) async {
    try {
      final effectiveUserId = await _resolveUserId(
        int.tryParse(userId.toString()),
      );
      final db = await _dbHelper.database;
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
      final formattedDate = '${now.day} ${months[now.month - 1]} ${now.year}';

      // 1. Sync badge award to Cloud Firestore unconditionally if user is authenticated
      try {
        final activeUser = await PreferenceHandler.getUser();
        final rawUid = userId?.toString() ?? '';
        final uid = (rawUid.isNotEmpty && rawUid != '1' && rawUid != '0' && rawUid != 'usr_default')
            ? rawUid
            : (activeUser?.id ?? '');
        if (uid.isNotEmpty && uid != '0' && uid != '1' && uid != 'usr_default') {
          await _remoteDataSource?.awardBadge(uid, badgeId, formattedDate);
        }
      } catch (_) {}

      // 2. Check local SQLite record
      final existing = await db.query(
        DatabaseHelper.tableUserBadges,
        where: 'user_id = ? AND badge_id = ?',
        whereArgs: [effectiveUserId, badgeId],
      );

      final bool alreadyUnlocked =
          existing.isNotEmpty &&
          existing.any((row) => (row['is_unlocked'] as int? ?? 0) == 1);

      if (alreadyUnlocked) {
        return const Success(false);
      }

      if (existing.isNotEmpty) {
        await db.update(
          DatabaseHelper.tableUserBadges,
          {
            'is_unlocked': 1,
            'current_progress': 1,
            'unlocked_at': formattedDate,
          },
          where: 'user_id = ? AND badge_id = ?',
          whereArgs: [effectiveUserId, badgeId],
        );
      } else {
        await db.insert(
          DatabaseHelper.tableUserBadges,
          {
            'id': 'ub_${effectiveUserId}_$badgeId',
            'user_id': effectiveUserId,
            'badge_id': badgeId,
            'is_unlocked': 1,
            'current_progress': 1,
            'unlocked_at': formattedDate,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final countResult = await db.rawQuery(
        '''
        SELECT COUNT(DISTINCT badge_id) as count FROM ${DatabaseHelper.tableUserBadges}
        WHERE user_id = ? AND is_unlocked = 1
      ''',
        [effectiveUserId],
      );
      final count = (countResult.first['count'] as int?) ?? 1;
      await db.update(
        DatabaseHelper.tableUsers,
        {'unlocked_badges_count': count},
        where: 'id = ?',
        whereArgs: [effectiveUserId],
      );

      return const Success(true);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  BadgeItem _mapRowToBadgeItem(Map<String, dynamic> row) {
    final iconName = row['icon_name'] as String? ?? 'sprout';
    final bgColorHex = row['bg_color_hex'] as String? ?? '#EBF7F1';
    final accentColorHex = row['accent_color_hex'] as String? ?? '#2D6A4F';

    return BadgeItem(
      id: row['id'] as String? ?? '',
      title: row['title'] as String? ?? '',
      desc: row['description'] as String? ?? '',
      iconName: iconName,
      isUnlocked: (row['is_unlocked'] as int?) == 1,
      unlockedDate: row['unlocked_at'] as String?,
      level: (row['level'] as int?) ?? 1,
      progress: (row['current_progress'] as int?) ?? 0,
      total: (row['target_total'] as int?) ?? 1,
      bgColorHex: bgColorHex,
      accentColorHex: accentColorHex,
      tierName: row['tier_name'] as String? ?? '',
    );
  }
}
