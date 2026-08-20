import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/data/datasources/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseHelper Schema & Migration Tests', () {
    test('Initializes tables with growth_stage and all required columns', () async {
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
      expect(columnNames.contains('nickname'), isTrue);
      expect(columnNames.contains('user_id'), isTrue);

      // Verify growth_logs columns
      final growthLogsColumns =
          await db.rawQuery('PRAGMA table_info(${DatabaseHelper.tableGrowthLogs})');
      final logColumnNames =
          growthLogsColumns.map((col) => col['name'] as String).toSet();

      expect(logColumnNames.contains('source'), isTrue);
      expect(logColumnNames.contains('height_cm'), isTrue);

      await dbHelper.close();
    });

    test('Self-healing _ensureSchemaColumns adds missing columns to existing DB', () async {
      final dbName =
          'db_migration_test_${DateTime.now().microsecondsSinceEpoch}.db';
      final databasesPath = await getDatabasesPath();
      final path = '$databasesPath/$dbName';

      // Create a legacy v1 database without growth_stage column
      final legacyDb = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE ${DatabaseHelper.tableUserPlants} (
              id TEXT PRIMARY KEY,
              user_id INTEGER NOT NULL,
              nickname TEXT NOT NULL
            );
          ''');
        },
      );
      await legacyDb.close();

      // Open through DatabaseHelper with version 2 and _onOpen self-healing
      final dbHelper = DatabaseHelper.forTesting(dbName);
      final upgradedDb = await dbHelper.database;

      final cols = await upgradedDb
          .rawQuery('PRAGMA table_info(${DatabaseHelper.tableUserPlants})');
      final colNames = cols.map((col) => col['name'] as String).toSet();

      expect(colNames.contains('growth_stage'), isTrue);
      expect(colNames.contains('initial_height_cm'), isTrue);

      await dbHelper.close();
    });
  });
}
