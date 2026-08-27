import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/features/garden/data/data_sources/plant_remote_data_source.dart';
import 'package:plenty/features/garden/data/repositories/plant_repository_impl.dart';
import 'package:plenty/features/garden/domain/models/perenual/perenual_care_guide_model.dart';
import 'package:plenty/features/garden/domain/models/perenual/perenual_detail_model.dart';
import 'package:plenty/features/garden/domain/models/perenual/perenual_species_model.dart';
import 'package:plenty/features/garden/domain/models/perenual/plant_catalog_model.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';
import 'package:plenty/features/garden/domain/repositories/plant_repository.dart';
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
    int speciesId,
  ) async {
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

  group('PlantRepositoryImpl Zero-Persistent-Cache Tests', () {
    test(
      'Fetches from remote API and caches in-memory session (2nd call hits session cache with 0 API calls)',
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

        // 1. First fetch -> calls remote API
        final result = await repository.getCatalogPlants(query: 'Rubber');
        expect(result.isSuccess, isTrue);
        final plants = (result as Success<List<PlantCatalogModel>>).data;
        expect(plants.length, 1);
        expect(plants.first.id, 'perenual_101');
        expect(plants.first.commonName, 'Ficus Elastica (Rubber Plant)');
        expect(mockRemoteDataSource.fetchListCalls, 1);

        // 2. Second fetch with same query -> Served from in-memory session cache!
        final secondResult = await repository.getCatalogPlants(query: 'Rubber');
        expect(secondResult.isSuccess, isTrue);
        expect(mockRemoteDataSource.fetchListCalls, 1); // Still 1 call!
      },
    );

    test(
      'Force refresh bypasses in-memory session cache and calls remote API',
      () async {
        mockRemoteDataSource.mockSpeciesList = [
          const PerenualSpeciesModel(
            id: 202,
            commonName: 'Updated New Name',
            watering: 'Frequent',
          ),
        ];

        // 1. First call
        await repository.getCatalogPlants(query: 'test');
        expect(mockRemoteDataSource.fetchListCalls, 1);

        // 2. Call with forceRefresh: true -> should call remote again
        final refreshed = await repository.getCatalogPlants(
          query: 'test',
          forceRefresh: true,
        );
        expect(refreshed.isSuccess, isTrue);
        expect(mockRemoteDataSource.fetchListCalls, 2);
      },
    );

    test(
      'Falls back to in-memory pre-seeded catalog when offline / remote API fails',
      () async {
        mockRemoteDataSource.shouldThrow = true;

        final result = await repository.getCatalogPlants();

        // Should gracefully fall back to in-memory pre-seeded species
        expect(result.isSuccess, isTrue);
        final plants = (result as Success<List<PlantCatalogModel>>).data;
        expect(plants, isNotEmpty);
        expect(plants.any((p) => p.commonName.contains('Monstera')), isTrue);
      },
    );

    test(
      'getPlantCatalogDetails retrieves from remote and caches in session memory',
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

        // 2. Fetch details again for 777 -> served from in-memory session cache
        final cachedResult = await repository.getPlantCatalogDetails(777);
        expect(cachedResult.isSuccess, isTrue);
        expect(mockRemoteDataSource.fetchDetailsCalls, 1); // 0 extra calls
      },
    );

    test(
      'getPlantCareGuides retrieves care instructions from remote API',
      () async {
        mockRemoteDataSource.mockCareGuides = [
          const PerenualCareGuideModel(
            id: 50,
            speciesId: 777,
            commonName: 'Snake Plant',
            sections: [
              PerenualCareGuideSection(
                type: 'watering',
                description:
                    'Allow soil to dry out completely between waterings.',
              ),
            ],
          ),
        ];

        final result = await repository.getPlantCareGuides(777);
        expect(result.isSuccess, isTrue);
        final guides = (result as Success<List<PerenualCareGuideModel>>).data;
        expect(guides.length, 1);
        expect(guides.first.speciesId, 777);
        expect(
          guides.first.wateringAdvice,
          'Allow soil to dry out completely between waterings.',
        );
        expect(mockRemoteDataSource.fetchCareGuidesCalls, 1);
      },
    );

    test(
      'addPlant persists self-contained snapshot directly into user_plants with zero catalog table interaction',
      () async {
        final species = PlantCatalogModel(
          id: 'perenual_101',
          commonName: 'Rubber Plant',
          scientificName: 'Ficus elastica',
          family: 'Moraceae',
          defaultWateringInterval: 7,
          sunlightLevel: 'Sinar Tidak Langsung Terang',
          careLevel: 'EASY CARE',
          cachedAt: DateTime.now(),
        );

        final addResult = await repository.addPlant(
          userId: '1',
          species: species,
          nickname: 'My Rubber',
          isIndoor: true,
          siteId: 'site_default_ruang_tamu',
          initialHeightCm: 45.0,
        );

        expect(addResult.isSuccess, isTrue);
        final added = (addResult as Success<AddPlantResult>).data;
        expect(added.plant.nickname, 'My Rubber');
        expect(added.plant.commonName, 'Rubber Plant');
        expect(added.isFirstPlant, isTrue);

        // Verify user_plants table has self-contained snapshot
        final userPlants = await repository.getUserPlants('1');
        expect(userPlants.isSuccess, isTrue);
        final plants = (userPlants as Success<List<PlantModel>>).data;
        expect(plants.length, 1);
        expect(plants.first.nickname, 'My Rubber');
        expect(plants.first.commonName, 'Rubber Plant');
        expect(plants.first.defaultWateringInterval, 7);
      },
    );
  });
}
