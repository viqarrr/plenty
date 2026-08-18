import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/utils/result.dart';
import 'package:plenty/data/datasources/database_helper.dart';
import 'package:plenty/data/datasources/plant_remote_data_source.dart';
import 'package:plenty/data/models/perenual_care_guide_model.dart';
import 'package:plenty/data/models/perenual_detail_model.dart';
import 'package:plenty/data/models/perenual_species_model.dart';
import 'package:plenty/data/models/plant_catalog_model.dart';
import 'package:plenty/data/repositories/plant_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockPlantRemoteDataSource implements PlantRemoteDataSource {
  int fetchListCalls = 0;
  int fetchDetailsCalls = 0;
  int fetchCareGuidesCalls = 0;
  List<PerenualSpeciesModel> mockSpeciesList = [];
  PerenualDetailModel? mockDetail;
  List<PerenualCareGuideModel> mockCareGuides = [];
  bool shouldThrow = false;

  @override
  Future<List<PerenualSpeciesModel>> fetchSpeciesList({
    int page = 1,
    String? query,
    int? indoor,
    String? watering,
    String? sunlight,
  }) async {
    fetchListCalls++;
    if (shouldThrow) throw const NetworkFailure('No internet connection');
    return mockSpeciesList;
  }

  @override
  Future<PerenualDetailModel> fetchSpeciesDetails(int speciesId) async {
    fetchDetailsCalls++;
    if (shouldThrow) throw const NetworkFailure('No internet connection');
    if (mockDetail != null) return mockDetail!;
    throw const NotFoundFailure('Plant not found');
  }

  @override
  Future<List<PerenualCareGuideModel>> fetchSpeciesCareGuides(
      int speciesId) async {
    fetchCareGuidesCalls++;
    if (shouldThrow) throw const NetworkFailure('No internet connection');
    return mockCareGuides;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late MockPlantRemoteDataSource mockRemoteDataSource;
  late PlantRepositoryImpl repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final dbName =
        'plant_repo_impl_test_${DateTime.now().microsecondsSinceEpoch}.db';
    dbHelper = DatabaseHelper.forTesting(dbName);
    await dbHelper.deleteDb();

    mockRemoteDataSource = MockPlantRemoteDataSource();
    repository = PlantRepositoryImpl(
      dbHelper: dbHelper,
      remoteDataSource: mockRemoteDataSource,
    );
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('PlantRepositoryImpl Cache-First Tests', () {
    test(
        'Returns local cached items immediately without network call when cache exists',
        () async {
      // 1. Pre-insert a plant into SQLite
      final db = await dbHelper.database;
      final cachedPlant = PlantCatalogModel(
        id: 'cat_local_1',
        commonName: 'Cached Monstera',
        scientificName: 'Monstera deliciosa',
        family: 'Araceae',
        defaultWateringInterval: 7,
        sunlightLevel: 'Bright indirect',
        careLevel: 'EASY CARE',
        cachedAt: DateTime.now(),
      );
      await db.insert(DatabaseHelper.tablePlantCatalog, cachedPlant.toMap());

      // 2. Fetch catalog plants
      final result = await repository.getCatalogPlants();

      // 3. Verify: Served from local cache, 0 remote API calls made! (Quota preserved)
      expect(result.isSuccess, isTrue);
      final plants = (result as Success<List<PlantCatalogModel>>).data;
      expect(plants.length, 1);
      expect(plants.first.commonName, 'Cached Monstera');
      expect(mockRemoteDataSource.fetchListCalls, 0);
    });

    test(
        'Fetches from remote API, saves to SQLite, and returns result when local cache is empty',
        () async {
      mockRemoteDataSource.mockSpeciesList = [
        const PerenualSpeciesModel(
          id: 101,
          commonName: 'Ficus Elastica (Rubber Plant)',
          scientificName: ['Ficus elastica'],
          family: 'Moraceae',
          watering: 'Average',
          sunlight: ['bright indirect'],
          defaultImageUrl: 'https://perenual.com/rubber.jpg',
        ),
      ];

      // 1. Fetch from empty SQLite
      final result = await repository.getCatalogPlants(query: 'Rubber');

      // 2. Verify: 1 API call made, result returned
      expect(result.isSuccess, isTrue);
      final plants = (result as Success<List<PlantCatalogModel>>).data;
      expect(plants.length, 1);
      expect(plants.first.id, 'perenual_101');
      expect(plants.first.commonName, 'Ficus Elastica (Rubber Plant)');
      expect(mockRemoteDataSource.fetchListCalls, 1);

      // 3. Verify: Data has been persisted to SQLite
      final db = await dbHelper.database;
      final savedRows = await db.query(DatabaseHelper.tablePlantCatalog);
      expect(savedRows.length, 1);
      expect(savedRows.first['id'], 'perenual_101');
      expect(savedRows.first['common_name'], 'Ficus Elastica (Rubber Plant)');

      // 4. Fetch again -> Should now hit cache with 0 additional API calls!
      final secondResult = await repository.getCatalogPlants(query: 'Rubber');
      expect(secondResult.isSuccess, isTrue);
      expect(mockRemoteDataSource.fetchListCalls, 1); // still 1!
    });

    test(
        'Force refresh calls remote API even if local data exists and updates SQLite',
        () async {
      // 1. Pre-populate local cache
      final db = await dbHelper.database;
      final oldPlant = PlantCatalogModel(
        id: 'perenual_202',
        commonName: 'Old Name',
        defaultWateringInterval: 5,
        cachedAt: DateTime.now().subtract(const Duration(days: 10)),
      );
      await db.insert(DatabaseHelper.tablePlantCatalog, oldPlant.toMap());

      // 2. Set up remote mock with updated name
      mockRemoteDataSource.mockSpeciesList = [
        const PerenualSpeciesModel(
          id: 202,
          commonName: 'Updated New Name',
          watering: 'Frequent',
        ),
      ];

      // 3. Request with forceRefresh: true
      final result = await repository.getCatalogPlants(forceRefresh: true);

      expect(result.isSuccess, isTrue);
      expect(mockRemoteDataSource.fetchListCalls, 1);
      final plants = (result as Success<List<PlantCatalogModel>>).data;
      expect(plants.first.commonName, 'Updated New Name');

      // 4. Verify SQLite updated
      final updatedRows = await db.query(DatabaseHelper.tablePlantCatalog);
      expect(updatedRows.first['common_name'], 'Updated New Name');
    });

    test(
        'Falls back to pre-seeded catalog when offline / remote API fails and cache is empty',
        () async {
      mockRemoteDataSource.shouldThrow = true;

      final result = await repository.getCatalogPlants();

      // Should gracefully fall back to pre-seeded offline species
      expect(result.isSuccess, isTrue);
      final plants = (result as Success<List<PlantCatalogModel>>).data;
      expect(plants, isNotEmpty);
      expect(plants.any((p) => p.commonName.contains('Monstera')), isTrue);
    });

    test(
        'getPlantCatalogDetails retrieves from cache or fetches and saves from remote',
        () async {
      mockRemoteDataSource.mockDetail = const PerenualDetailModel(
        id: 777,
        commonName: 'Snake Plant Detailed',
        scientificName: ['Dracaena trifasciata'],
        family: 'Asparagaceae',
        careLevel: 'Low',
        maintenance: 'Low',
        watering: 'Minimum',
        poisonousToPets: true,
        poisonousToHumans: false,
      );

      // 1. Fetch details for 777 -> remote call
      final result = await repository.getPlantCatalogDetails(777);
      expect(result.isSuccess, isTrue);
      final detail = (result as Success<PlantCatalogModel>).data;
      expect(detail.id, 'perenual_777');
      expect(detail.commonName, 'Snake Plant Detailed');
      expect(detail.careLevel, 'EASY CARE');
      expect(mockRemoteDataSource.fetchDetailsCalls, 1);

      // 2. Fetch details again for 777 -> served from SQLite cache
      final cachedResult = await repository.getPlantCatalogDetails(777);
      expect(cachedResult.isSuccess, isTrue);
      expect(mockRemoteDataSource.fetchDetailsCalls, 1); // 0 extra calls
    });

    test('getPlantCareGuides retrieves care instructions from remote API',
        () async {
      mockRemoteDataSource.mockCareGuides = [
        const PerenualCareGuideModel(
          id: 50,
          speciesId: 777,
          commonName: 'Snake Plant',
          sections: [
            PerenualCareGuideSection(
              type: 'watering',
              description: 'Allow soil to dry out completely between waterings.',
            ),
          ],
        ),
      ];

      final result = await repository.getPlantCareGuides(777);
      expect(result.isSuccess, isTrue);
      final guides = (result as Success<List<PerenualCareGuideModel>>).data;
      expect(guides.length, 1);
      expect(guides.first.speciesId, 777);
      expect(guides.first.wateringAdvice,
          'Allow soil to dry out completely between waterings.');
      expect(mockRemoteDataSource.fetchCareGuidesCalls, 1);
    });
  });
}
