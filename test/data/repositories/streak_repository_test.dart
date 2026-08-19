import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/data/datasources/database_helper.dart';
import 'package:plenty/data/datasources/preference_handler.dart';
import 'package:plenty/data/repositories/streak_repository.dart';
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
      expect(streak.currentStreak, 1);
      expect(streak.currentTier, 1);
      expect(streak.freezeTokensAvailable, 1);
      expect(PreferenceHandler.streakCount, 1);
    });

    test('getStreak returns existing record without overwriting', () async {
      final db = await dbHelper.database;
      await db.insert(
        DatabaseHelper.tableUserStreaks,
        {
          'id': 'streak_1',
          'user_id': 1,
          'current_streak': 14,
          'longest_streak': 20,
          'current_tier': 5,
          'last_streak_date': '2026-08-18',
          'freeze_tokens_available': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final streak = await streakRepo.getStreak('1');

      expect(streak.currentStreak, 14);
      expect(streak.currentTier, 5);
      expect(streak.freezeTokensAvailable, 0);
    });
  });
}
