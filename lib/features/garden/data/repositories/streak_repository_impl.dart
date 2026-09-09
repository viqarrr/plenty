import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/auth/domain/models/user_model.dart';
import 'package:plenty/features/garden/domain/models/streak_model.dart';
import 'package:plenty/features/garden/domain/repositories/streak_repository.dart';
import 'package:plenty/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:plenty/features/profile/domain/repositories/badge_repository.dart';
import 'package:plenty/features/profile/data/repositories/badge_repository_impl.dart';

/// Repository implementation managing user streak calculation and updating users table.
class StreakRepositoryImpl implements IStreakRepository {
  final DatabaseHelper _dbHelper;
  final IBadgeRepository _badgeRepo;
  final ProfileRemoteDataSource _remoteDataSource;

  StreakRepositoryImpl({
    DatabaseHelper? dbHelper,
    IBadgeRepository? badgeRepo,
    ProfileRemoteDataSource? remoteDataSource,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _badgeRepo = badgeRepo ?? BadgeRepositoryImpl(dbHelper: dbHelper),
        _remoteDataSource =
            remoteDataSource ?? FirestoreProfileRemoteDataSourceImpl();

  static String _formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<Result<List<String>>> getDistinctActiveLogDates(String userId) async {
    try {
      final db = await _dbHelper.database;
      UserModel? activeUser;
      try {
        activeUser = await PreferenceHandler.getUser();
      } catch (_) {}
      final effectiveUserId = (userId.isNotEmpty && userId != '1' && userId != 'usr_default')
          ? userId
          : (activeUser?.id ?? userId);
      final parsedUserId = int.tryParse(effectiveUserId);
      final rows = await db.rawQuery('''
        SELECT DISTINCT COALESCE(NULLIF(c.log_date, ''), SUBSTR(c.completed_at, 1, 10)) AS log_date
        FROM ${DatabaseHelper.tableCareActionLogs} c
        JOIN ${DatabaseHelper.tableUserPlants} p ON c.user_plant_id = p.id
        WHERE (p.user_id = ? OR CAST(p.user_id AS TEXT) = ? OR p.user_id = ? OR p.user_id = 'usr_default')
        ORDER BY log_date DESC
      ''', [parsedUserId ?? effectiveUserId, effectiveUserId, activeUser?.id ?? '']);

      final dates = rows
          .map((r) => r['log_date'] as String?)
          .where((d) => d != null && d.isNotEmpty)
          .cast<String>()
          .toList();
      return Success(dates);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

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
      checkDate = today;
    } else {
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

  Future<UserStreakModel> _getRawStreakRecord(String userId) async {
    final db = await _dbHelper.database;
    UserModel? activeUser;
    try {
      activeUser = await PreferenceHandler.getUser();
    } catch (_) {}
    final effectiveUserId = (userId.isNotEmpty && userId != '1' && userId != 'usr_default')
        ? userId
        : (activeUser?.id ?? userId);
    final parsedUserId = int.tryParse(effectiveUserId);

    final results = await db.query(
      DatabaseHelper.tableUsers,
      where: 'id = ? OR email = ?',
      whereArgs: [parsedUserId ?? activeUser?.numericId ?? 1, activeUser?.email ?? ''],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return UserStreakModel.fromUserMap(results.first);
    }

    if (activeUser != null) {
      return UserStreakModel(
        userId: effectiveUserId,
        currentStreak: activeUser.streakCount,
        longestStreak: activeUser.longestStreak,
        currentTier: UserStreakModel.calculateTier(activeUser.streakCount),
        lastStreakDate: activeUser.lastStreakDate,
        freezeTokensAvailable: 1,
      );
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

  @override
  Future<Result<UserStreakModel>> getStreak(String userId) async {
    try {
      UserModel? activeUser;
      try {
        activeUser = await PreferenceHandler.getUser();
      } catch (_) {}
      final effectiveUserId = (userId.isNotEmpty && userId != '1' && userId != 'usr_default')
          ? userId
          : (activeUser?.id ?? userId);

      // 1. Try remote Firestore if available
      if (effectiveUserId.isNotEmpty && effectiveUserId != '1' && effectiveUserId != 'usr_default') {
        try {
          final remoteUser = await _remoteDataSource.getUserProfile(effectiveUserId);
          if (remoteUser != null && remoteUser.streakCount > 0) {
            final streak = UserStreakModel(
              userId: effectiveUserId,
              currentStreak: remoteUser.streakCount,
              longestStreak: remoteUser.longestStreak,
              currentTier: UserStreakModel.calculateTier(remoteUser.streakCount),
              lastStreakDate: remoteUser.lastStreakDate,
              freezeTokensAvailable: 1,
            );
            await _saveStreak(streak);
            return Success(streak);
          }
        } catch (_) {}
      }

      // 2. Fallback to local record
      final db = await _dbHelper.database;
      final parsedUserId = int.tryParse(effectiveUserId);
      final results = await db.query(
        DatabaseHelper.tableUsers,
        where: 'id = ? OR email = ?',
        whereArgs: [parsedUserId ?? activeUser?.numericId ?? 1, activeUser?.email ?? ''],
        limit: 1,
      );

      if (results.isNotEmpty) {
        final streak = UserStreakModel.fromUserMap(results.first);
        try {
          await PreferenceHandler.setStreakCount(streak.currentStreak);
        } catch (_) {}
        return Success(streak);
      }

      return await evaluateDailyStreak(effectiveUserId);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<UserStreakModel>> evaluateDailyStreak(String userId) async {
    try {
      final activeUser = await PreferenceHandler.getUser();
      final effectiveUserId = (userId.isNotEmpty && userId != '1' && userId != 'usr_default')
          ? userId
          : (activeUser?.id ?? userId);
      final todayStr = _formatDate(DateTime.now());
      final current = await _getRawStreakRecord(effectiveUserId);
      final distinctDatesRes = await getDistinctActiveLogDates(effectiveUserId);
      final distinctDates = distinctDatesRes.dataOrNull ?? [];

      int computedStreak;
      if (distinctDates.isEmpty) {
        computedStreak = current.currentStreak > 0 ? current.currentStreak : 1;
      } else {
        computedStreak = calculateStreakCount(
          distinctDates: distinctDates,
          now: DateTime.now(),
          freezeTokens: current.freezeTokensAvailable,
        );
        if (current.currentStreak > computedStreak) {
          computedStreak = current.currentStreak;
        }
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

      if (computedStreak >= 7) {
        await _badgeRepo.awardBadge(userId: effectiveUserId, badgeId: 'water_streak');
      }

      return Success(updated);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  Future<void> _saveStreak(UserStreakModel streak) async {
    final db = await _dbHelper.database;
    UserModel? activeUser;
    try {
      activeUser = await PreferenceHandler.getUser();
    } catch (_) {}
    final parsedUserId = int.tryParse(streak.userId);
    int? targetId = parsedUserId ?? activeUser?.numericId;

    if (activeUser?.email != null && activeUser!.email.isNotEmpty) {
      final rows = await db.query(
        DatabaseHelper.tableUsers,
        columns: ['id'],
        where: 'email = ?',
        whereArgs: [activeUser.email],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        targetId = rows.first['id'] as int;
      }
    }

    if (targetId != null) {
      await db.update(
        DatabaseHelper.tableUsers,
        {
          'streak_count': streak.currentStreak,
          'longest_streak': streak.longestStreak,
          'last_streak_date': streak.lastStreakDate,
        },
        where: 'id = ?',
        whereArgs: [targetId],
      );
    }

    try {
      await PreferenceHandler.setStreakCount(streak.currentStreak);
      if (activeUser != null) {
        await PreferenceHandler.setUser(activeUser.copyWith(
          streakCount: streak.currentStreak,
          longestStreak: streak.longestStreak,
          lastStreakDate: streak.lastStreakDate,
        ));
      }
    } catch (_) {}

    // Sync streak metrics with Cloud Firestore
    try {
      final uid = (activeUser?.id != null && activeUser!.id!.isNotEmpty)
          ? activeUser.id!
          : streak.userId;
      if (uid.isNotEmpty && uid != '0' && uid != '1' && uid != 'usr_default') {
        await _remoteDataSource.updateUserStreak(
          uid,
          streak: streak.currentStreak,
          longestStreak: streak.longestStreak,
          lastStreakDate: streak.lastStreakDate,
        );
      }
    } catch (_) {}
  }
}
