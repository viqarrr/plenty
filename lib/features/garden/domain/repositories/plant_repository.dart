import 'package:plenty/core/utils/result.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';
import 'package:plenty/features/garden/domain/models/time_capsule_model.dart';
import 'package:plenty/features/plant_catalog/domain/models/perenual_care_guide_model.dart';
import 'package:plenty/features/plant_catalog/domain/models/plant_catalog_model.dart';

/// Result returned after confirming plant adoption flow.
class AddPlantResult {
  final PlantModel plant;
  final bool isFirstPlant;

  const AddPlantResult({required this.plant, required this.isFirstPlant});
}

/// Abstract contract for botanical catalog and user plant repository.
abstract class IPlantRepository {
  /// Retrieves plant catalog with Cache-First strategy.
  Future<Result<List<PlantCatalogModel>>> getCatalogPlants({
    String? query,
    int page = 1,
    bool forceRefresh = false,
  });

  /// Retrieves botanical details for a specific species ID.
  Future<Result<PlantCatalogModel>> getPlantCatalogDetails(
    int speciesId, {
    bool forceRefresh = false,
  });

  /// Retrieves structured care guides for a species ID.
  Future<Result<List<PerenualCareGuideModel>>> getPlantCareGuides(int speciesId);

  /// Seeds catalog from pre-bundled `assets/data/seed_plants.json`.
  Future<Result<List<PlantCatalogModel>>> seedCatalogFromAsset({String? query});

  /// Unified Add Plant Flow: Atomic insertion of user plant, initial growth log, care schedule, and time capsule.
  Future<Result<AddPlantResult>> addPlant({
    required String userId,
    PlantCatalogModel? species,
    String? catalogId,
    required String nickname,
    required bool isIndoor,
    String? sunlightCondition,
    String? potSize,
    String? site,
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
    String? site,
  });

  /// Updates the cover photo path for an adopted plant.
  Future<Result<void>> updatePlantPhoto(String plantId, String? photoPath);

  /// Permanently deletes an adopted plant and cascades deletions.
  Future<Result<void>> deletePlant(String plantId);
}
