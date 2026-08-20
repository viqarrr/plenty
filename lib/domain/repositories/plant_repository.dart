import 'package:plenty/core/utils/result.dart';
import 'package:plenty/data/models/perenual_care_guide_model.dart';
import 'package:plenty/data/models/plant_catalog_model.dart';
import 'package:plenty/data/models/plant_model.dart';
import 'package:plenty/data/models/time_capsule_model.dart';
import 'package:plenty/data/repositories/plant_repository.dart';

/// Clean Architecture Repository Interface for Botanical Plant Catalog and User Plant operations.
abstract class IPlantRepository {
  /// Fetches botanical plant species using Cache-First pattern (local SQLite first, fallback to Perenual API).
  Future<Result<List<PlantCatalogModel>>> getCatalogPlants({
    String? query,
    int page = 1,
    bool forceRefresh = false,
  });

  /// Fetches detailed botanical species information by ID with Cache-First strategy.
  Future<Result<PlantCatalogModel>> getPlantCatalogDetails(
    int speciesId, {
    bool forceRefresh = false,
  });

  /// Fetches botanical care guides (watering, sunlight, pruning) for a specific species ID.
  Future<Result<List<PerenualCareGuideModel>>> getPlantCareGuides(int speciesId);

  /// Unified Add Plant Flow: Atomic insertion of user plant, initial growth log, care schedule, and time capsule.
  Future<Result<AddPlantResult>> addPlant({
    required String userId,
    PlantCatalogModel? species,
    String? catalogId,
    required String nickname,
    required bool isIndoor,
    String? sunlightCondition,
    String? potSize,
    String? windowDistance,
    double? initialHeightCm,
    String growthStage = 'mature',
    String? coverPhotoPath,
    String? customPhotoPath,
    TimeCapsuleDraft? timeCapsule,
    int defaultWateringInterval = 3,
  });

  /// Retrieves active user adopted plants.
  Future<Result<List<PlantModel>>> getUserPlants([String userId = 'usr_default']);

  /// Retrieves a specific adopted plant by ID.
  Future<Result<PlantModel?>> getPlantById(String plantId);

  /// Archives an adopted plant.
  Future<Result<void>> archivePlant(String plantId);

  /// Updates an adopted plant's nickname and/or cover photo.
  Future<Result<void>> updatePlantInfo({
    required String plantId,
    required String nickname,
    String? coverPhotoPath,
    bool updatePhoto = false,
  });

  /// Updates the cover photo path for an adopted plant.
  Future<Result<void>> updatePlantPhoto(String plantId, String? photoPath);

  /// Permanently deletes an adopted plant.
  Future<Result<void>> deletePlant(String plantId);

  /// Seeds the local SQLite catalog from pre-seeded asset `assets/data/seed_plants.json`.
  Future<Result<List<PlantCatalogModel>>> seedCatalogFromAsset();
}
