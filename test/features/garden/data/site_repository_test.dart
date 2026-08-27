import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/constants/site_icons.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/features/garden/data/repositories/site_repository_impl.dart';
import 'package:plenty/features/garden/domain/models/site_model.dart';
import 'package:plenty/features/garden/domain/repositories/site_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late ISiteRepository siteRepo;

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
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    siteRepo = SiteRepositoryImpl(dbHelper: dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('SiteRepository CRUD & Default Site Protection Tests', () {
    test('Can save, fetch, update, and delete custom sites while protecting defaults', () async {
      // 1. Initial fetch should contain 5 default seeded sites
      final initialSitesRes = await siteRepo.getSites('1');
      final initialSites = initialSitesRes.dataOrNull ?? [];
      expect(initialSites.length, 5);
      expect(initialSites.every((s) => s.isCustom == false), isTrue);

      // 2. Add custom site
      final newSite = SiteModel(
        id: 'site_rooftop_1',
        userId: '1',
        name: 'Rooftop Garden',
        iconCode: Icons.roofing_outlined.codePoint,
        isIndoor: false,
        isCustom: true,
        createdAt: DateTime.now(),
      );
      final addResult = await siteRepo.addCustomSite(newSite);
      expect(addResult, isA<Success<void>>());

      // 3. Fetch all sites (default first, then custom)
      final savedSitesRes = await siteRepo.getSites('1');
      final savedSites = savedSitesRes.dataOrNull ?? [];
      expect(savedSites.length, 6);
      expect(savedSites.last.id, 'site_rooftop_1');
      expect(savedSites.last.name, 'Rooftop Garden');
      expect(savedSites.last.isCustom, true);
      expect(savedSites.last.isIndoor, false);

      // 4. Update custom site
      final updatedSite = savedSites.last.copyWith(
        name: 'Rooftop Sunset Oasis',
      );
      final updateResult = await siteRepo.updateCustomSite(updatedSite);
      expect(updateResult, isA<Success<void>>());

      final reFetchedRes = await siteRepo.getSites('1');
      final reFetched = reFetchedRes.dataOrNull ?? [];
      expect(reFetched.last.name, 'Rooftop Sunset Oasis');

      // 5. Default sites cannot be updated
      final defaultSite = initialSites.first;
      final tryUpdateDefault = await siteRepo.updateCustomSite(
        defaultSite.copyWith(name: 'Hacked Living Room'),
      );
      expect(tryUpdateDefault, isA<Error<void>>());
      final updateFailure = (tryUpdateDefault as Error<void>).failure;
      expect(updateFailure, isA<ValidationFailure>());
      expect(
        updateFailure.message,
        'Site bawaan aplikasi tidak dapat diubah atau dihapus.',
      );

      // 6. Default sites cannot be deleted
      final tryDeleteDefault =
          await siteRepo.deleteCustomSite(SiteIcons.defaultLivingRoomId);
      expect(tryDeleteDefault, isA<Error<void>>());
      final deleteFailure = (tryDeleteDefault as Error<void>).failure;
      expect(deleteFailure, isA<ValidationFailure>());
      expect(
        deleteFailure.message,
        'Site bawaan aplikasi tidak dapat diubah atau dihapus.',
      );

      // 7. Delete custom site succeeds
      final deleteCustomResult =
          await siteRepo.deleteCustomSite('site_rooftop_1');
      expect(deleteCustomResult, isA<Success<void>>());

      final afterDeleteRes = await siteRepo.getSites('1');
      final afterDelete = afterDeleteRes.dataOrNull ?? [];
      expect(afterDelete.length, 5);
      expect(afterDelete.any((s) => s.id == 'site_rooftop_1'), isFalse);
    });
  });
}
