import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plenty/data/datasources/database_helper.dart';
import 'package:plenty/data/models/badge_model.dart';
import 'package:plenty/data/models/user_badge_model.dart';
import 'package:sqflite/sqflite.dart';

/// Repository managing achievement badges, seeding initial badges,
/// and awarding badges to users.
class BadgeRepository {
  final DatabaseHelper _dbHelper;

  BadgeRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static const List<BadgeModel> defaultBadges = [
    BadgeModel(
      id: 'FIRST_PLANT',
      title: 'Tunas Pertama 🌱',
      description: 'Menambahkan tanaman pertamamu ke taman Plenty.',
      iconAssetPath: 'assets/images/badges/badge_first_plant.png',
    ),
    BadgeModel(
      id: 'STREAK_3',
      title: 'Konsisten Pemula 🔥',
      description: 'Merawat tanaman selama 3 hari berturut-turut.',
      iconAssetPath: 'assets/images/badges/badge_streak_3.png',
    ),
    BadgeModel(
      id: 'STREAK_7',
      title: 'Tangan Hijau 🌿',
      description: 'Menjaga streak perawatan selama 7 hari penuh.',
      iconAssetPath: 'assets/images/badges/badge_streak_7.png',
    ),
    BadgeModel(
      id: 'STREAK_30',
      title: 'Penjaga Hutan 🌳',
      description: 'Dedikasi luar biasa! 30 hari streak perawatan.',
      iconAssetPath: 'assets/images/badges/badge_streak_30.png',
    ),
    BadgeModel(
      id: 'TIME_CAPSULE_CREATOR',
      title: 'Penyimpan Kenangan ⏳',
      description: 'Membuat Kapsul Waktu pertama untuk tanamanmu.',
      iconAssetPath: 'assets/images/badges/badge_capsule.png',
    ),
    BadgeModel(
      id: 'PLANT_LEVEL_5',
      title: 'Ahli Botani 🏆',
      description: 'Berhasil menaikkan level tanaman hingga Level 5.',
      iconAssetPath: 'assets/images/badges/badge_level_5.png',
    ),
  ];

  /// Seeds master badges into the `badges` table if not already present.
  Future<void> seedInitialBadges() async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (final badge in defaultBadges) {
      batch.insert(
        DatabaseHelper.tableBadges,
        badge.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Awards a badge to the user if they don't already possess it.
  /// Returns `true` if a new badge was awarded, `false` if already possessed.
  Future<bool> awardBadge({
    required String userId,
    required String badgeId,
  }) async {
    final db = await _dbHelper.database;
    final parsedUserId = int.tryParse(userId.toString()) ?? 1;

    // Ensure master badges exist
    await seedInitialBadges();

    // Ensure user exists before inserting foreign key relation
    final userRows = await db.query(
      DatabaseHelper.tableUsers,
      where: 'id = ?',
      whereArgs: [parsedUserId],
      limit: 1,
    );
    if (userRows.isEmpty) {
      await db.insert(
        DatabaseHelper.tableUsers,
        {
          'id': parsedUserId,
          'email': 'user_$parsedUserId@plenty.app',
          'username': 'user_$parsedUserId',
          'display_name': 'Pecinta Tanaman',
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    final existing = await db.query(
      DatabaseHelper.tableUserBadges,
      where: 'user_id = ? AND badge_id = ?',
      whereArgs: [parsedUserId, badgeId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return false; // Already unlocked
    }

    final id = 'ub_${DateTime.now().millisecondsSinceEpoch}_$badgeId';
    await db.insert(
      DatabaseHelper.tableUserBadges,
      {
        'id': id,
        'user_id': parsedUserId,
        'badge_id': badgeId,
        'unlocked_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    return true;
  }

  /// Retrieves all badges earned by a user, joined with master badge data.
  Future<List<UserBadgeModel>> getUserBadges(String userId) async {
    final db = await _dbHelper.database;
    final parsedUserId = int.tryParse(userId.toString()) ?? 1;
    await seedInitialBadges();

    final results = await db.rawQuery('''
      SELECT 
        ub.id AS ub_id,
        ub.user_id,
        ub.badge_id,
        ub.unlocked_at,
        b.id AS b_id,
        b.title,
        b.description,
        b.icon_asset_path
      FROM ${DatabaseHelper.tableUserBadges} ub
      JOIN ${DatabaseHelper.tableBadges} b ON ub.badge_id = b.id
      WHERE ub.user_id = ?
      ORDER BY ub.unlocked_at DESC
    ''', [parsedUserId]);

    return results.map((r) {
      final badge = BadgeModel(
        id: r['b_id'] as String,
        title: r['title'] as String,
        description: r['description'] as String,
        iconAssetPath: r['icon_asset_path'] as String,
      );

      return UserBadgeModel.fromMap(
        {
          'id': r['ub_id'] as String,
          'user_id': r['user_id'].toString(),
          'badge_id': r['badge_id'] as String,
          'unlocked_at': r['unlocked_at'] as String,
        },
        badge: badge,
      );
    }).toList();
  }

  /// Checks if a user has unlocked a specific badge.
  Future<bool> hasBadge(String userId, String badgeId) async {
    final db = await _dbHelper.database;
    final parsedUserId = int.tryParse(userId.toString()) ?? 1;
    final results = await db.query(
      DatabaseHelper.tableUserBadges,
      where: 'user_id = ? AND badge_id = ?',
      whereArgs: [parsedUserId, badgeId],
      limit: 1,
    );
    return results.isNotEmpty;
  }
}

final badgeRepositoryProvider = Provider<BadgeRepository>((ref) {
  return BadgeRepository();
});
