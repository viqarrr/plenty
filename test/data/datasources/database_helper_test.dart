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
      expect(columnNames.contains('site'), isTrue);
      expect(columnNames.contains('nickname'), isTrue);
      expect(columnNames.contains('user_id'), isTrue);

      // Verify growth_logs columns
      final growthLogsColumns =
          await db.rawQuery('PRAGMA table_info(${DatabaseHelper.tableGrowthLogs})');
      final logColumnNames =
          growthLogsColumns.map((col) => col['name'] as String).toSet();

      expect(logColumnNames.contains('source'), isTrue);
      expect(logColumnNames.contains('height_cm'), isTrue);

      // Verify custom_sites columns
      final customSitesColumns =
          await db.rawQuery('PRAGMA table_info(${DatabaseHelper.tableCustomSites})');
      final customSitesColumnNames =
          customSitesColumns.map((col) => col['name'] as String).toSet();

      expect(customSitesColumnNames.contains('name'), isTrue);
      expect(customSitesColumnNames.contains('icon_code'), isTrue);
      expect(customSitesColumnNames.contains('is_indoor'), isTrue);

      // Verify default user seeded
      final users = await db.query(DatabaseHelper.tableUsers);
      expect(users.isNotEmpty, isTrue);
      expect(users.first['email'], 'default@plenty.app');

      await dbHelper.close();
    });
  });
}
