import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/profile/domain/models/badge_item.dart';
import 'package:plenty/features/profile/domain/repositories/badge_repository.dart';
import 'package:sqflite/sqflite.dart';

/// Implementation of IBadgeRepository for SQLite database.
class BadgeRepositoryImpl implements IBadgeRepository {
  final DatabaseHelper _dbHelper;

  BadgeRepositoryImpl({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<int> _resolveUserId(int? userId) async {
    if (userId != null && userId != 0) return userId;
    try {
      final activeUser = await PreferenceHandler.getUser();
      if (activeUser != null && activeUser.id != null && activeUser.id != 0) {
        return activeUser.id!;
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

      final badges = rows.map(_mapRowToBadgeItem).toList();
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
      final effectiveUserId = await _resolveUserId(userId);
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        '''
        SELECT COUNT(DISTINCT badge_id) as count 
        FROM ${DatabaseHelper.tableUserBadges}
        WHERE user_id = ? AND is_unlocked = 1
      ''',
        [effectiveUserId],
      );

      if (result.isNotEmpty) {
        return Success((result.first['count'] as int?) ?? 0);
      }
      return const Success(0);
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
