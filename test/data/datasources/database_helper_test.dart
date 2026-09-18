import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseHelper Schema Tests', () {
    test('Initializes tables with growth_stage, site, and all required columns', () async {
      final dbHelper = DatabaseHelper.forTesting(
        'db_schema_test_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      await dbHelper.deleteDb();

      final db = await dbHelper.database;

      // Verify user_plants columns
      final userPlantsColumns =
          await db.rawQuery('PRAGMA table_info(${DatabaseHelper.tableUserPlants})');
      final columnNames =
          userPlantsColumns.map((col) => col['name'] as String).toSet();

      expect(columnNames.contains('growth_stage'), isTrue);
      expect(columnNames.contains('initial_height_cm'), isTrue);
      expect(columnNames.contains('site_id'), isTrue);
      expect(columnNames.contains('nickname'), isTrue);
      expect(columnNames.contains('user_id'), isTrue);

      // Verify growth_logs columns
      final growthLogsColumns =
          await db.rawQuery('PRAGMA table_info(${DatabaseHelper.tableGrowthLogs})');
      final logColumnNames =
          growthLogsColumns.map((col) => col['name'] as String).toSet();

      expect(logColumnNames.contains('source'), isTrue);
      expect(logColumnNames.contains('height_cm'), isTrue);

      // Verify sites columns
      final sitesColumns =
          await db.rawQuery('PRAGMA table_info(${DatabaseHelper.tableSites})');
      final sitesColumnNames =
          sitesColumns.map((col) => col['name'] as String).toSet();

      expect(sitesColumnNames.contains('name'), isTrue);
      expect(sitesColumnNames.contains('icon_code'), isTrue);
      expect(sitesColumnNames.contains('is_indoor'), isTrue);
      expect(sitesColumnNames.contains('is_custom'), isTrue);

      // Verify default sites seeded
      final defaultSites = await db.query(
        DatabaseHelper.tableSites,
        where: 'is_custom = 0',
      );
      expect(defaultSites.length, equals(5));

      // Verify badges columns
      final badgesColumns =
          await db.rawQuery('PRAGMA table_info(${DatabaseHelper.tableBadges})');
      final badgeColumnNames =
          badgesColumns.map((col) => col['name'] as String).toSet();

      expect(badgeColumnNames.contains('icon_name'), isTrue);
      expect(badgeColumnNames.contains('tier_name'), isTrue);
      expect(badgeColumnNames.contains('level'), isTrue);
      expect(badgeColumnNames.contains('target_total'), isTrue);
      expect(badgeColumnNames.contains('bg_color_hex'), isTrue);
      expect(badgeColumnNames.contains('accent_color_hex'), isTrue);

      // Verify user_badges columns
      final userBadgesColumns = await db
          .rawQuery('PRAGMA table_info(${DatabaseHelper.tableUserBadges})');
      final userBadgeColumnNames =
          userBadgesColumns.map((col) => col['name'] as String).toSet();

      expect(userBadgeColumnNames.contains('badge_id'), isTrue);
      expect(userBadgeColumnNames.contains('user_id'), isTrue);
      expect(userBadgeColumnNames.contains('is_unlocked'), isTrue);
      expect(userBadgeColumnNames.contains('current_progress'), isTrue);
      expect(userBadgeColumnNames.contains('unlocked_at'), isTrue);

      // Verify initial master badges seeded
      final masterBadges = await db.query(DatabaseHelper.tableBadges);
      expect(masterBadges.length, equals(4));

      // Verify user badges are NOT pre-seeded for dummy accounts (clean state)
      final userBadges = await db.query(DatabaseHelper.tableUserBadges);
      expect(userBadges.isEmpty, isTrue);

      // Verify no default dummy user is seeded (security best practice: no hardcoded accounts)
      final users = await db.query(DatabaseHelper.tableUsers);
      expect(users.isEmpty, isTrue);

      // Verify obsolete tables (post_comments, post_likes) are not created
      final obsoleteTables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('post_comments', 'post_likes')",
      );
      expect(obsoleteTables.isEmpty, isTrue);

      await dbHelper.close();
    });
  });
}
