import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/garden/domain/models/streak_model.dart';
import 'package:plenty/features/garden/data/repositories/badge_repository.dart';

/// Repository managing user streak calculation and updating users table.
class StreakRepository {
  final DatabaseHelper _dbHelper;
  final BadgeRepository _badgeRepo;

  StreakRepository({
    DatabaseHelper? dbHelper,
    BadgeRepository? badgeRepo,
    dynamic careRepo,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _badgeRepo = badgeRepo ?? BadgeRepository(dbHelper: dbHelper);

  /// Formats date to 'YYYY-MM-DD'
  static String _formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// Retrieves distinct active care log dates for a user.
  Future<List<String>> getDistinctActiveLogDates(String userId) async {
    final db = await _dbHelper.database;
    final parsedUserId = int.tryParse(userId);
    final rows = await db.rawQuery('''
      SELECT DISTINCT COALESCE(NULLIF(c.log_date, ''), SUBSTR(c.completed_at, 1, 10)) AS log_date
      FROM ${DatabaseHelper.tableCareActionLogs} c
      JOIN ${DatabaseHelper.tableUserPlants} p ON c.user_plant_id = p.id
      WHERE (p.user_id = ? OR CAST(p.user_id AS TEXT) = ?)
      ORDER BY log_date DESC
    ''', [parsedUserId ?? userId, userId]);

    return rows
        .map((r) => r['log_date'] as String?)
        .where((d) => d != null && d.isNotEmpty)
        .cast<String>()
        .toList();
  }

  /// Calculates consecutive daily streak from distinct active care dates.
  int calculateStreakCount({
    required List<String> distinctDates,
    required DateTime now,
    int freezeTokens = 0,
  }) {
    if (distinctDates.isEmpty) {
      return 1;
    }

    final dateSet = distinctDates.toSet();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = _formatDate(today);

    DateTime checkDate;
    if (dateSet.contains(todayStr)) {
      // User has active log today -> count chain starting from today
      checkDate = today;
    } else {
      // Today is still active and uncompleted -> check chain backwards from yesterday
      checkDate = today.subtract(const Duration(days: 1));
    }

    int streak = 0;
    int availableTokens = freezeTokens;

    while (true) {
      final dateStr = _formatDate(checkDate);
      if (dateSet.contains(dateStr)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        final hasPriorActivity = dateSet.any((d) => d.compareTo(dateStr) < 0);
        if (hasPriorActivity && availableTokens > 0) {
          availableTokens--;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }

    return streak > 0 ? streak : 1;
  }

  /// Retrieves the raw user streak record from SQLite users table or creates default.
  Future<UserStreakModel> _getRawStreakRecord(String userId) async {
    final db = await _dbHelper.database;
    final parsedUserId = int.tryParse(userId) ?? 1;
    final results = await db.query(
      DatabaseHelper.tableUsers,
      where: 'id = ?',
      whereArgs: [parsedUserId],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return UserStreakModel.fromUserMap(results.first);
    }

    return UserStreakModel(
      userId: userId,
      currentStreak: 1,
      longestStreak: 1,
      currentTier: 1,
      lastStreakDate: null,
      freezeTokensAvailable: 1,
    );
  }

  /// Retrieves evaluated streak record for a user from users table.
  Future<UserStreakModel> getStreak(String userId) async {
    final db = await _dbHelper.database;
    final parsedUserId = int.tryParse(userId) ?? 1;
    final results = await db.query(
      DatabaseHelper.tableUsers,
      where: 'id = ?',
      whereArgs: [parsedUserId],
      limit: 1,
    );

    if (results.isNotEmpty) {
      final streak = UserStreakModel.fromUserMap(results.first);
      await PreferenceHandler.setStreakCount(streak.currentStreak);
      return streak;
    }

    return evaluateDailyStreak(userId);
  }

  /// Evaluates and updates the daily streak upon routine completion or dashboard load.
  Future<UserStreakModel> evaluateDailyStreak(String userId) async {
    final todayStr = _formatDate(DateTime.now());
    final current = await _getRawStreakRecord(userId);
    final distinctDates = await getDistinctActiveLogDates(userId);

    int computedStreak;
    if (distinctDates.isEmpty) {
      computedStreak = current.currentStreak > 0 ? current.currentStreak : 1;
    } else {
      computedStreak = calculateStreakCount(
        distinctDates: distinctDates,
        now: DateTime.now(),
        freezeTokens: current.freezeTokensAvailable,
      );
    }

    final newLongest = computedStreak > current.longestStreak
        ? computedStreak
        : current.longestStreak;
    final newTier = UserStreakModel.calculateTier(computedStreak);

    final updated = current.copyWith(
      currentStreak: computedStreak,
      longestStreak: newLongest,
      currentTier: newTier,
      lastStreakDate: todayStr,
    );

    await _saveStreak(updated);

    if (computedStreak >= 3) {
      await _badgeRepo.awardBadge(userId: userId, badgeId: 'STREAK_3');
    }
    if (computedStreak >= 7) {
      await _badgeRepo.awardBadge(userId: userId, badgeId: 'STREAK_7');
    }
    if (computedStreak >= 30) {
      await _badgeRepo.awardBadge(userId: userId, badgeId: 'STREAK_30');
    }

    return updated;
  }

  Future<void> _saveStreak(UserStreakModel streak) async {
    final db = await _dbHelper.database;
    final parsedUserId = int.tryParse(streak.userId) ?? 1;

    await db.update(
      DatabaseHelper.tableUsers,
      {
        'streak_count': streak.currentStreak,
        'longest_streak': streak.longestStreak,
        'last_streak_date': streak.lastStreakDate,
      },
      where: 'id = ?',
      whereArgs: [parsedUserId],
    );

    await PreferenceHandler.setStreakCount(streak.currentStreak);
  }
}
