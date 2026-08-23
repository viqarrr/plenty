import 'package:plenty/core/domain/models/growth_log_model.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/features/garden/domain/models/time_capsule_model.dart';

/// State of a plant's time capsule.
enum TimeCapsuleState { none, locked, unlocked }

/// Contract interface for Growth & Time Capsule Repository.
abstract interface class IGrowthRepository {
  /// Retrieves height data points ordered chronologically for plotting growth graphs.
  Future<Result<List<GrowthLogModel>>> getHeightSeries(String userPlantId);

  /// Retrieves growth logs for the photo timeline and growth history gallery.
  Future<Result<List<GrowthLogModel>>> getPhotoGallery(String userPlantId);

  /// Retrieves the current time capsule state for a plant.
  Future<Result<TimeCapsuleState>> getTimeCapsuleState(String userPlantId);

  /// Retrieves the stored time capsule for a plant.
  Future<Result<TimeCapsuleModel?>> getTimeCapsule(String userPlantId);

  /// Saves or creates a new time capsule record for a plant.
  Future<Result<void>> saveTimeCapsule(TimeCapsuleModel capsule);

  /// Marks a time capsule as unlocked.
  Future<Result<void>> unlockTimeCapsule(String capsuleId);

  /// Adds a new historical growth entry.
  Future<Result<void>> addGrowthLog(GrowthLogModel log);
}
