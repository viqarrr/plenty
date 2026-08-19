import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plenty/data/datasources/database_helper.dart';
import 'package:plenty/data/datasources/preference_handler.dart';
import 'package:plenty/data/models/user_streak_model.dart';
import 'package:plenty/data/repositories/badge_repository.dart';
import 'package:plenty/data/repositories/care_repository.dart';
import 'package:sqflite/sqflite.dart';

/// Repository managing user streak calculation, freeze tokens,
/// and daily routine task evaluation.
class StreakRepository {
  final DatabaseHelper _dbHelper;
  final CareRepository _careRepo;
  final BadgeRepository _badgeRepo;

  StreakRepository({
    DatabaseHelper? dbHelper,
    CareRepository? careRepo,
    BadgeRepository? badgeRepo,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _careRepo = careRepo ?? CareRepository(dbHelper: dbHelper),
        _badgeRepo = badgeRepo ?? BadgeRepository(dbHelper: dbHelper);

  /// Formats date to 'YYYY-MM-DD'
  static String _formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// Retrieves or initializes streak record for a user.
  Future<UserStreakModel> getStreak(String userId) async {
    final db = await _dbHelper.database;
    final parsedUserId = int.tryParse(userId) ?? 1;
    final results = await db.query(
      DatabaseHelper.tableUserStreaks,
      where: 'user_id = ?',
      whereArgs: [parsedUserId],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return UserStreakModel.fromMap(results.first);
    }

    // Initialize default streak record
    final initial = UserStreakModel(
      userId: userId,
      currentStreak: 1,
      longestStreak: 1,
      currentTier: 1,
      lastStreakDate: _formatDate(DateTime.now()),
      freezeTokensAvailable: 1,
    );

    await db.insert(
      DatabaseHelper.tableUserStreaks,
      initial.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await PreferenceHandler.setStreakCount(1);
    return initial;
  }

  /// Evaluates and updates the daily streak upon routine completion or dashboard load.
  ///
  /// Logic:
  /// 1. If already updated today -> return current state.
  /// 2. If yesterday's tasks were all completed or today's tasks are all completed -> increment streak.
  /// 3. If missed a day:
  ///    - If freeze token available -> consume freeze token, preserve streak.
  ///    - Otherwise -> reset streak to 1.
  Future<UserStreakModel> evaluateDailyStreak(String userId) async {
    final current = await getStreak(userId);
    final todayStr = _formatDate(DateTime.now());

    if (current.lastStreakDate == todayStr) {
      // Already evaluated for today
      return current;
    }

    final isAllDone = await _careRepo.isAllTasksCompleteTodayForUser(userId);
    if (!isAllDone) {
      // Check if user missed more than 1 day
      if (current.lastStreakDate != null) {
        final lastDate = DateTime.tryParse(current.lastStreakDate!);
        if (lastDate != null) {
          final differenceInDays = DateTime.now().difference(lastDate).inDays;
          if (differenceInDays > 1) {
            // User missed days
            if (current.freezeTokensAvailable > 0) {
              // Consume freeze token
              final updated = current.copyWith(
                freezeTokensAvailable: current.freezeTokensAvailable - 1,
                freezeUsedOn: todayStr,
                lastStreakDate: todayStr,
              );
              await _saveStreak(updated);
              return updated;
            } else {
              // Reset streak to 1
              final updated = current.copyWith(
                currentStreak: 1,
                currentTier: 1,
                lastStreakDate: todayStr,
              );
              await _saveStreak(updated);
              return updated;
            }
          }
        }
      }
      return current;
    }

    // All tasks completed today -> increment streak
    final newStreak = current.currentStreak + 1;
    final newLongest =
        newStreak > current.longestStreak ? newStreak : current.longestStreak;
    final newTier = UserStreakModel.calculateTier(newStreak);

    final updated = current.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongest,
      currentTier: newTier,
      lastStreakDate: todayStr,
    );

    await _saveStreak(updated);

    // Check for streak-based badge achievements
    if (newStreak >= 3) {
      await _badgeRepo.awardBadge(userId: userId, badgeId: 'STREAK_3');
    }
    if (newStreak >= 7) {
      await _badgeRepo.awardBadge(userId: userId, badgeId: 'STREAK_7');
    }
    if (newStreak >= 30) {
      await _badgeRepo.awardBadge(userId: userId, badgeId: 'STREAK_30');
    }

    return updated;
  }

  Future<void> _saveStreak(UserStreakModel streak) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseHelper.tableUserStreaks,
      streak.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await PreferenceHandler.setStreakCount(streak.currentStreak);
  }
}

final streakRepositoryProvider = Provider<StreakRepository>((ref) {
  return StreakRepository();
});
