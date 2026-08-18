import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/utils/debouncer.dart';
import 'package:plenty/data/datasources/database_helper.dart';
import 'package:plenty/data/datasources/plant_remote_data_source.dart';
import 'package:plenty/data/models/perenual_care_guide_model.dart';
import 'package:plenty/data/models/perenual_detail_model.dart';
import 'package:plenty/data/models/perenual_species_model.dart';
import 'package:plenty/data/models/plant_catalog_model.dart';
import 'package:plenty/data/repositories/plant_repository.dart';
import 'package:plenty/presentation/species/choose_species_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakePlantRemoteDataSource implements PlantRemoteDataSource {
  List<PerenualSpeciesModel> mockList = [];

  @override
  Future<List<PerenualSpeciesModel>> fetchSpeciesList({
    int page = 1,
    String? query,
    int? indoor,
    String? watering,
    String? sunlight,
  }) async {
    return mockList;
  }

  @override
  Future<PerenualDetailModel> fetchSpeciesDetails(int speciesId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<PerenualCareGuideModel>> fetchSpeciesCareGuides(
      int speciesId) async {
    return [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late PlantRepository plantRepository;
  late FakePlantRemoteDataSource fakeRemoteDataSource;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final dbName =
        'choose_species_test_${DateTime.now().microsecondsSinceEpoch}.db';
    dbHelper = DatabaseHelper.forTesting(dbName);
    await dbHelper.deleteDb();

    fakeRemoteDataSource = FakePlantRemoteDataSource();
    plantRepository = PlantRepository(
      dbHelper: dbHelper,
      remoteDataSource: fakeRemoteDataSource,
    );

    // Pre-populate SQLite with seed test plants
    final db = await dbHelper.database;
    final testPlants = [
      PlantCatalogModel(
        id: 'cat_monstera',
        commonName: 'Monstera Deliciosa',
        scientificName: 'Monstera deliciosa',
        family: 'Araceae',
        defaultWateringInterval: 7,
        sunlightLevel: 'Sinar Tidak Langsung Terang',
        careLevel: 'EASY CARE',
        cachedAt: DateTime.now(),
      ),
      PlantCatalogModel(
        id: 'cat_snake_plant',
        commonName: 'Snake Plant',
        scientificName: 'Dracaena trifasciata',
        family: 'Asparagaceae',
        defaultWateringInterval: 14,
        sunlightLevel: 'Pencahayaan Rendah',
        careLevel: 'EASY CARE',
        cachedAt: DateTime.now(),
      ),
      PlantCatalogModel(
        id: 'cat_calathea',
        commonName: 'Calathea Orbifolia',
        scientificName: 'Calathea orbifolia',
        family: 'Marantaceae',
        defaultWateringInterval: 4,
        sunlightLevel: 'Sinar Sedang',
        careLevel: 'INTERMEDIATE',
        cachedAt: DateTime.now(),
      ),
    ];

    for (final plant in testPlants) {
      await db.insert(DatabaseHelper.tablePlantCatalog, plant.toMap());
    }
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('ChooseSpeciesController Unit Tests', () {
    test('Initial state reflects defaults and loads initial catalog list',
        () async {
      final controller = ChooseSpeciesController(
        plantRepository: plantRepository,
        debouncer: Debouncer(delay: const Duration(milliseconds: 50)),
      );

      // Wait for initial load
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.state.query, '');
      expect(controller.state.careFilter, 'Semua');
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.speciesList.length, 3);
      expect(controller.state.filteredList.length, 3);

      controller.dispose();
    });

    test('onSearchChanged sets isLoading true, debounces query, and updates list',
        () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 100));
      final controller = ChooseSpeciesController(
        plantRepository: plantRepository,
        debouncer: debouncer,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Trigger search
      controller.onSearchChanged('monstera');

      // Immediately: query is set, isLoading is true
      expect(controller.state.query, 'monstera');
      expect(controller.state.isLoading, isTrue);

      // Wait for debouncer delay to lapse
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.filteredList.length, 1);
      expect(controller.state.filteredList.first.commonName,
          'Monstera Deliciosa');

      controller.dispose();
    });

    test('Filtering by care level filters list by Easy Care and Low Light',
        () async {
      final controller = ChooseSpeciesController(
        plantRepository: plantRepository,
        debouncer: Debouncer(delay: const Duration(milliseconds: 50)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Initial count is 3
      expect(controller.state.filteredList.length, 3);

      // 1. Filter by Easy Care -> Monstera & Snake Plant (2)
      controller.setCareFilter('Easy Care');
      expect(controller.state.careFilter, 'Easy Care');
      expect(controller.state.filteredList.length, 2);
      expect(
        controller.state.filteredList.map((p) => p.commonName),
        containsAll(['Monstera Deliciosa', 'Snake Plant']),
      );

      // 2. Filter by Pencahayaan Rendah -> Snake Plant (1)
      controller.setCareFilter('Pencahayaan Rendah');
      expect(controller.state.careFilter, 'Pencahayaan Rendah');
      expect(controller.state.filteredList.length, 1);
      expect(controller.state.filteredList.first.commonName, 'Snake Plant');

      // 3. Reset filter to 'Semua' -> All 3
      controller.setCareFilter('Semua');
      expect(controller.state.filteredList.length, 3);

      controller.dispose();
    });
  });
}
