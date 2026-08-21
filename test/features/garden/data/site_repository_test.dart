import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/features/garden/data/repositories/site_repository.dart';
import 'package:plenty/features/garden/domain/models/custom_site_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late SiteRepository siteRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final uniqueName =
        'site_repo_test_${DateTime.now().microsecondsSinceEpoch}.db';
    dbHelper = DatabaseHelper.forTesting(uniqueName);
    await dbHelper.deleteDb();

    final db = await dbHelper.database;
    await db.insert(
      DatabaseHelper.tableUsers,
      {
        'id': 1,
        'email': 'site_test@plenty.app',
        'display_name': 'Site Tester',
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    siteRepo = SiteRepository(dbHelper: dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('SiteRepository CRUD Tests', () {
    test('Can save, fetch, update, and delete custom sites in SQLite', () async {
      final initialSites = await siteRepo.getCustomSites('1');
      expect(initialSites, isEmpty);

      // 1. Create
      final newSite = CustomSiteModel(
        id: 'site_rooftop_1',
        userId: '1',
        name: 'Rooftop Garden',
        iconCode: Icons.roofing_outlined.codePoint,
        isIndoor: false,
        createdAt: DateTime.now(),
      );
      await siteRepo.saveCustomSite(newSite);

      // 2. Read
      final savedSites = await siteRepo.getCustomSites('1');
      expect(savedSites.length, 1);
      expect(savedSites.first.id, 'site_rooftop_1');
      expect(savedSites.first.name, 'Rooftop Garden');
      expect(savedSites.first.isIndoor, false);

      // 3. Update
      final updatedSite = savedSites.first.copyWith(
        name: 'Rooftop Sunset Oasis',
      );
      await siteRepo.updateCustomSite(updatedSite);

      final reFetched = await siteRepo.getCustomSites('1');
      expect(reFetched.first.name, 'Rooftop Sunset Oasis');

      // 4. Delete
      await siteRepo.deleteCustomSite('site_rooftop_1');
      final afterDelete = await siteRepo.getCustomSites('1');
      expect(afterDelete, isEmpty);
    });
  });
}
