import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/garden/data/repositories/streak_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper dbHelper;
  late StreakRepository streakRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferenceHandler.init();

    dbHelper = DatabaseHelper.forTesting('streak_repo_test.db');
    await dbHelper.deleteDb();
    streakRepo = StreakRepository(dbHelper: dbHelper);

    final db = await dbHelper.database;
    await db.insert(
      DatabaseHelper.tableUsers,
      {
        'id': 1,
        'email': 'test@plenty.app',
        'display_name': 'Test User',
        'streak_count': 0,
        'longest_streak': 0,
        'total_xp': 0,
        'level': 1,
        'unlocked_badges_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('StreakRepository', () {
    test('getStreak initializes record if not existing', () async {
      final streak = await streakRepo.getStreak('1');

      expect(streak.userId, '1');
      expect(streak.currentStreak, 0);
      expect(streak.currentTier, 1);
      expect(PreferenceHandler.streakCount, 0);
    });

    test('getStreak returns existing record without overwriting', () async {
      final db = await dbHelper.database;
      await db.update(
        DatabaseHelper.tableUsers,
        {
          'streak_count': 14,
          'longest_streak': 20,
          'last_streak_date': '2026-08-18',
        },
        where: 'id = ?',
        whereArgs: [1],
      );

      final streak = await streakRepo.getStreak('1');

      expect(streak.currentStreak, 14);
      expect(streak.currentTier, 5);
      expect(streak.longestStreak, 20);
    });

    test('evaluateDailyStreak calculates streak = 2 for yesterday + today care logs', () async {
      final db = await dbHelper.database;
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} 10:00:00';
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')} 10:00:00';

      // Insert plant
      await db.insert(
        DatabaseHelper.tableUserPlants,
        {
          'id': 'plt_streak_test',
          'user_id': '1',
          'nickname': 'Streak Test Plant',
          'is_indoor': 1,
          'adopted_at': yesterdayStr,
        },
      );

      // Insert log yesterday
      await db.insert(
        DatabaseHelper.tableCareActionLogs,
        {
          'id': 'log_yesterday',
          'user_plant_id': 'plt_streak_test',
          'task_type': 'siram',
          'xp_awarded': 10,
          'completed_at': yesterdayStr,
        },
      );

      // Insert log today
      await db.insert(
        DatabaseHelper.tableCareActionLogs,
        {
          'id': 'log_today',
          'user_plant_id': 'plt_streak_test',
          'task_type': 'siram',
          'xp_awarded': 10,
          'completed_at': todayStr,
        },
      );

      final result = await streakRepo.evaluateDailyStreak('1');

      expect(result.currentStreak, 2);
      expect(PreferenceHandler.streakCount, 2);
    });
  });
}
