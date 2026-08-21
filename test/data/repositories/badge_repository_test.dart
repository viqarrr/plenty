import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/features/garden/data/repositories/badge_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper dbHelper;
  late BadgeRepository badgeRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper.forTesting('badge_repo_test.db');
    await dbHelper.deleteDb();
    badgeRepo = BadgeRepository(dbHelper: dbHelper);

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
    await badgeRepo.seedInitialBadges();
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('BadgeRepository', () {
    test('seedInitialBadges inserts default badges', () async {
      await badgeRepo.seedInitialBadges();
      final db = await dbHelper.database;
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseHelper.tableBadges}'),
      );

      expect(count, equals(BadgeRepository.defaultBadges.length));
    });

    test('awardBadge unlocks new badge and prevents duplicates', () async {
      final awardedFirst = await badgeRepo.awardBadge(
        userId: '1',
        badgeId: 'FIRST_PLANT',
      );
      expect(awardedFirst, isTrue);

      final hasFirstPlant =
          await badgeRepo.hasBadge('1', 'FIRST_PLANT');
      expect(hasFirstPlant, isTrue);

      // Second attempt should return false (already unlocked)
      final awardedAgain = await badgeRepo.awardBadge(
        userId: '1',
        badgeId: 'FIRST_PLANT',
      );
      expect(awardedAgain, isFalse);

      final badges = await badgeRepo.getUserBadges('1');
      expect(badges.length, 1);
      expect(badges.first.badge?.title, 'Tunas Pertama 🌱');
    });
  });
}
