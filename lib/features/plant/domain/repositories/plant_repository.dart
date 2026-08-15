import 'package:plenty/core/utils/result.dart';
import 'package:plenty/features/plant/domain/entities/care_task_entity.dart';
import 'package:plenty/features/plant/domain/entities/plant_entity.dart';

/// Contract interface for Plant repository.
abstract interface class PlantRepository {
  /// Retrieve list of plants owned by the user.
  Future<Result<List<PlantEntity>>> getUserPlants();

  /// Retrieve catalog list of plant species available in the app.
  Future<Result<List<PlantEntity>>> getCatalogPlants();

  /// Add a plant to user's collection.
  Future<Result<void>> addUserPlant(PlantEntity plant);

  /// Remove a plant from user's collection.
  Future<Result<void>> removeUserPlant(String plantId);

  /// Update an existing plant in user's collection.
  Future<Result<void>> updatePlant(PlantEntity plant);

  /// Mark a watering or cleaning care task as complete.
  Future<Result<void>> completeTask(CareTaskEntity task);

  /// Retrieve the current user profile name.
  Future<Result<String>> getProfileName();

  /// Set the user profile name.
  Future<Result<void>> setProfileName(String name);

  /// Get current streak count.
  Future<Result<int>> getStreakCount();

  /// Increment care streak count.
  Future<Result<int>> incrementStreak();
}
