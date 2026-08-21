import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/features/garden/domain/models/badge_model.dart';
import 'package:sqflite/sqflite.dart';

/// Repository managing achievement badges, seeding initial badges,
/// and awarding badges tracked directly on the users table.
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

  /// Awards a badge to the user and increments `unlocked_badges_count` on `users` table.
  /// Returns `true` if a new badge was awarded, `false` if already possessed.
  Future<bool> awardBadge({
    required String userId,
    required String badgeId,
  }) async {
    final db = await _dbHelper.database;
    final parsedUserId = int.tryParse(userId.toString()) ?? 1;

    await seedInitialBadges();

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
          'unlocked_badges_count': 1,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      return true;
    }

    final currentBadges =
        (userRows.first['unlocked_badges_count'] as int?) ?? 0;
    final badgeIndex = defaultBadges.indexWhere((b) => b.id == badgeId);
    final targetIndex = badgeIndex != -1 ? badgeIndex : currentBadges;

    // Already unlocked
    if (targetIndex < currentBadges) {
      return false;
    }

    final nextCount = (targetIndex + 1 > currentBadges)
        ? targetIndex + 1
        : currentBadges + 1;
    await db.update(
      DatabaseHelper.tableUsers,
      {'unlocked_badges_count': nextCount},
      where: 'id = ?',
      whereArgs: [parsedUserId],
    );

    return true;
  }

  /// Retrieves all unlocked badges for a user.
  Future<List<UserBadgeModel>> getUserBadges(String userId) async {
    final count = await getUserBadgeCount(userId);
    final unlockedBadges = defaultBadges.take(count).toList();

    return unlockedBadges.map((badge) {
      return UserBadgeModel(
        id: 'ub_${badge.id}',
        userId: userId,
        badgeId: badge.id,
        unlockedAt: DateTime.now(),
        badge: badge,
      );
    }).toList();
  }

  /// Checks if a user has unlocked a specific badge.
  Future<bool> hasBadge(String userId, String badgeId) async {
    final count = await getUserBadgeCount(userId);
    final badgeIndex = defaultBadges.indexWhere((b) => b.id == badgeId);
    if (badgeIndex == -1) return false;
    return badgeIndex < count;
  }

  /// Returns the total count of badges unlocked by a user directly from users table.
  Future<int> getUserBadgeCount([String? userId]) async {
    final db = await _dbHelper.database;
    final parsedUserId = int.tryParse(userId ?? '1') ?? 1;
    final userRows = await db.query(
      DatabaseHelper.tableUsers,
      columns: ['unlocked_badges_count'],
      where: 'id = ?',
      whereArgs: [parsedUserId],
      limit: 1,
    );

    if (userRows.isEmpty) return 0;
    return (userRows.first['unlocked_badges_count'] as int?) ?? 0;
  }
}
