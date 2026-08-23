import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/features/profile/data/repositories/badge_repository_impl.dart';
import 'package:plenty/features/profile/domain/repositories/badge_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper dbHelper;
  late IBadgeRepository badgeRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper.forTesting('badge_repo_test.db');
    await dbHelper.deleteDb();
    badgeRepo = BadgeRepositoryImpl(dbHelper: dbHelper);

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

  group('BadgeRepository', () {
    test('getBadges retrieves all seeded badges', () async {
      final badgesRes = await badgeRepo.getBadges(userId: 1);
      final badges = badgesRes.dataOrNull ?? [];
      expect(badges.isNotEmpty, isTrue);
    });

    test('awardBadge unlocks new badge and prevents duplicates', () async {
      final awardedFirstRes = await badgeRepo.awardBadge(
        userId: '1',
        badgeId: 'first_plant',
      );
      final awardedFirst = awardedFirstRes.dataOrNull ?? false;
      expect(awardedFirst, isTrue);

      final badgeRes = await badgeRepo.getBadgeById('first_plant', userId: 1);
      final badge = badgeRes.dataOrNull;
      expect(badge?.isUnlocked, isTrue);

      // Second attempt should return false (already unlocked)
      final awardedAgainRes = await badgeRepo.awardBadge(
        userId: '1',
        badgeId: 'first_plant',
      );
      final awardedAgain = awardedAgainRes.dataOrNull ?? true;
      expect(awardedAgain, isFalse);

      final unlockedCountRes = await badgeRepo.getUnlockedBadgeCount(userId: 1);
      final unlockedCount = unlockedCountRes.dataOrNull ?? 0;
      expect(unlockedCount, 1);
    });
  });
}
