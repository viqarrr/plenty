import 'package:plenty/data/datasources/database_helper.dart';
import 'package:plenty/data/datasources/plant_remote_data_source.dart';
import 'package:plenty/data/models/perenual_care_guide_model.dart';
import 'package:plenty/data/models/plant_catalog_model.dart';
import 'package:plenty/data/models/plant_model.dart';
import 'package:plenty/data/models/time_capsule_model.dart';
import 'package:plenty/data/repositories/plant_repository_impl.dart';

/// Result returned after confirming plant adoption flow.
class AddPlantResult {
  final PlantModel plant;
  final bool isFirstPlant;

  const AddPlantResult({required this.plant, required this.isFirstPlant});
}

/// Repository managing user plants, botanical catalog data, and adoption transactions.
/// Uses Cache-First strategy to minimize external API quota consumption.
class PlantRepository {
  final DatabaseHelper _dbHelper;
  final PlantRemoteDataSource _remoteDataSource;
  late final PlantRepositoryImpl _impl;

  PlantRepository({
    DatabaseHelper? dbHelper,
    PlantRemoteDataSource? remoteDataSource,
  }) : _dbHelper = dbHelper ?? DatabaseHelper.instance,
       _remoteDataSource = remoteDataSource ?? PlantRemoteDataSourceImpl() {
    _impl = PlantRepositoryImpl(
      dbHelper: _dbHelper,
      remoteDataSource: _remoteDataSource,
    );
  }

  DatabaseHelper get dbHelper => _dbHelper;
  PlantRemoteDataSource get remoteDataSource => _remoteDataSource;
  PlantRepositoryImpl get impl => _impl;

  /// Unified Add Plant Flow: Atomic insertion of user_plants, initial growth_logs entry,
  /// care_schedules, and optional time_capsules in a single transaction block.
  Future<AddPlantResult> addPlant({
    required String userId,
    PlantCatalogModel? species,
    String? catalogId,
    required String nickname,
    required bool isIndoor,
    String? sunlightCondition,
    String? potSize,
    String? windowDistance,
    double? initialHeightCm,
    String? coverPhotoPath,
    TimeCapsuleDraft? timeCapsule,
    int defaultWateringInterval = 3,
  }) async {
    final result = await _impl.addPlant(
      userId: userId,
      species: species,
      catalogId: catalogId,
      nickname: nickname,
      isIndoor: isIndoor,
      sunlightCondition: sunlightCondition,
      potSize: potSize,
      windowDistance: windowDistance,
      initialHeightCm: initialHeightCm,
      coverPhotoPath: coverPhotoPath,
      timeCapsule: timeCapsule,
      defaultWateringInterval: defaultWateringInterval,
    );

    return result.when(
      success: (data) => data,
      error: (failure) => throw Exception(failure.message),
    );
  }

  Future<List<PlantModel>> getUserPlants([String? userId]) async {
    final result = await _impl.getUserPlants(userId ?? 'usr_default');
    return result.dataOrNull ?? [];
  }

  Future<PlantModel?> getPlantById(String plantId) async {
    final result = await _impl.getPlantById(plantId);
    return result.when(
      success: (data) => data,
      error: (failure) => throw Exception(failure.message),
    );
  }

  /// Archives a plant by setting is_archived = 1.
  Future<void> archivePlant(String plantId) async {
    await _impl.archivePlant(plantId);
  }

  /// Permanently deletes a plant.
  Future<void> deletePlant(String plantId) async {
    await _impl.deletePlant(plantId);
  }

  /// Retrieves plant species catalog using Cache-First pattern (local SQLite first, fallback to Perenual API).
  Future<List<PlantCatalogModel>> getCatalogPlants({
    String? query,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final result = await _impl.getCatalogPlants(
      query: query,
      page: page,
      forceRefresh: forceRefresh,
    );
    return result.dataOrNull ?? [];
  }

  /// Searches the botanical catalog (Cache-First).
  Future<List<PlantCatalogModel>> searchCatalogPlants({
    required String query,
    int page = 1,
    bool forceRefresh = false,
  }) => getCatalogPlants(query: query, page: page, forceRefresh: forceRefresh);

  /// Retrieves detailed species information by ID with Cache-First strategy.
  Future<PlantCatalogModel?> getSpeciesDetails(
    int speciesId, {
    bool forceRefresh = false,
  }) async {
    final result = await _impl.getPlantCatalogDetails(
      speciesId,
      forceRefresh: forceRefresh,
    );
    return result.dataOrNull;
  }

  /// Retrieves structured care guides for a species ID.
  Future<List<PerenualCareGuideModel>> getPlantCareGuides(int speciesId) async {
    final result = await _impl.getPlantCareGuides(speciesId);
    return result.dataOrNull ?? [];
  }

  /// Seeds catalog from `assets/data/seed_plants.json`.
  Future<List<PlantCatalogModel>> seedCatalogFromAsset() async {
    final result = await _impl.seedCatalogFromAsset();
    return result.dataOrNull ?? [];
  }
}
