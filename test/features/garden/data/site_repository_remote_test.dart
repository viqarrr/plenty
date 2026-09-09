import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/features/garden/data/datasources/garden_remote_datasource.dart';
import 'package:plenty/features/garden/data/repositories/site_repository_impl.dart';
import 'package:plenty/features/garden/domain/models/site_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockGardenRemoteDataSource extends Mock
    implements GardenRemoteDataSource {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late MockGardenRemoteDataSource mockRemoteDataSource;
  late SiteRepositoryImpl siteRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    registerFallbackValue(
      SiteModel(
        id: 'fallback_site',
        name: 'Fallback',
        iconCode: 123,
        createdAt: DateTime.now(),
      ),
    );
  });

  setUp(() async {
    final uniqueName =
        'site_repo_remote_test_${DateTime.now().microsecondsSinceEpoch}.db';
    dbHelper = DatabaseHelper.forTesting(uniqueName);
    await dbHelper.deleteDb();

    mockRemoteDataSource = MockGardenRemoteDataSource();
    siteRepo = SiteRepositoryImpl(
      dbHelper: dbHelper,
      remoteDataSource: mockRemoteDataSource,
    );
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('SiteRepository Remote Sync & Offline Resilience Tests', () {
    test('getSites syncs remote sites into local cache and returns combined list', () async {
      final remoteSite = SiteModel(
        id: 'site_cloud_terrace',
        userId: 'user_uid_123',
        name: 'Teras Atas Awan',
        iconCode: Icons.deck.codePoint,
        isIndoor: false,
        isCustom: true,
        createdAt: DateTime.now(),
      );

      when(() => mockRemoteDataSource.getSites('user_uid_123'))
          .thenAnswer((_) async => [remoteSite]);

      final result = await siteRepo.getSites('user_uid_123');

      expect(result, isA<Success<List<SiteModel>>>());
      final sites = result.dataOrNull!;
      // 5 default seeded sites + 1 synced remote site
      expect(sites.length, 6);
      expect(sites.any((s) => s.id == 'site_cloud_terrace'), isTrue);
      verify(() => mockRemoteDataSource.getSites('user_uid_123')).called(1);
    });

    test('addCustomSite dual-writes to local SQLite and remote data source', () async {
      final newSite = SiteModel(
        id: 'site_zen_garden',
        userId: 'user_uid_123',
        name: 'Zen Garden',
        iconCode: Icons.spa.codePoint,
        isIndoor: false,
        isCustom: true,
        createdAt: DateTime.now(),
      );

      when(() => mockRemoteDataSource.saveSite(any()))
          .thenAnswer((_) async {});

      final addRes = await siteRepo.addCustomSite(newSite);
      expect(addRes, isA<Success<void>>());

      verify(() => mockRemoteDataSource.saveSite(any())).called(1);

      // Verify stored in local SQLite
      when(() => mockRemoteDataSource.getSites('user_uid_123'))
          .thenAnswer((_) async => []);
      final fetchRes = await siteRepo.getSites('user_uid_123');
      final sites = fetchRes.dataOrNull!;
      expect(sites.any((s) => s.id == 'site_zen_garden'), isTrue);
    });

    test('updateCustomSite updates local SQLite and remote data source', () async {
      final site = SiteModel(
        id: 'site_update_target',
        userId: 'user_uid_123',
        name: 'Ruang Baca Lama',
        iconCode: Icons.book.codePoint,
        isIndoor: true,
        isCustom: true,
        createdAt: DateTime.now(),
      );

      when(() => mockRemoteDataSource.saveSite(any()))
          .thenAnswer((_) async {});
      when(() => mockRemoteDataSource.updateSite(any()))
          .thenAnswer((_) async {});

      await siteRepo.addCustomSite(site);

      final updated = site.copyWith(name: 'Ruang Baca Nyaman');
      final updateRes = await siteRepo.updateCustomSite(updated);
      expect(updateRes, isA<Success<void>>());

      verify(() => mockRemoteDataSource.updateSite(any())).called(1);
    });

    test('deleteCustomSite deletes from SQLite and remote data source', () async {
      final site = SiteModel(
        id: 'site_del_target',
        userId: 'user_uid_123',
        name: 'Ruang Hapus',
        iconCode: Icons.delete.codePoint,
        isIndoor: true,
        isCustom: true,
        createdAt: DateTime.now(),
      );

      when(() => mockRemoteDataSource.saveSite(any()))
          .thenAnswer((_) async {});
      when(() => mockRemoteDataSource.deleteSite('site_del_target'))
          .thenAnswer((_) async {});

      await siteRepo.addCustomSite(site);
      final delRes = await siteRepo.deleteCustomSite('site_del_target');
      expect(delRes, isA<Success<void>>());

      verify(() => mockRemoteDataSource.deleteSite('site_del_target')).called(1);
    });

    test('Offline resilience: operations succeed locally even if remote throws', () async {
      when(() => mockRemoteDataSource.getSites(any()))
          .thenThrow(Exception('Firestore unreachable'));
      when(() => mockRemoteDataSource.saveSite(any()))
          .thenThrow(Exception('Firestore network failure'));

      final site = SiteModel(
        id: 'site_offline_created',
        userId: 'user_uid_123',
        name: 'Offline Room',
        iconCode: Icons.home.codePoint,
        isIndoor: true,
        isCustom: true,
        createdAt: DateTime.now(),
      );

      final addResult = await siteRepo.addCustomSite(site);
      expect(addResult, isA<Success<void>>());

      final getResult = await siteRepo.getSites('user_uid_123');
      expect(getResult, isA<Success<List<SiteModel>>>());
      expect(getResult.dataOrNull!.any((s) => s.id == 'site_offline_created'), isTrue);
    });
  });
}
