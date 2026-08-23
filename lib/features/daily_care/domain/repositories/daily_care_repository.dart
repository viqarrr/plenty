import 'package:plenty/core/error/result.dart';
import 'package:plenty/features/daily_care/domain/models/care_history_item.dart';
import 'package:plenty/features/daily_care/domain/models/daily_care_state.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';

/// Contract interface for Daily Care Repository.
abstract interface class IDailyCareRepository {
  /// Loads daily care state including height tasks, due cyclic schedules, and streak.
  Future<Result<DailyCareState>> loadDailyCareData({String? explicitUserId});

  /// Completes height monitoring task, awards XP, logs growth, and updates streak.
  Future<Result<void>> completeHeightTask({
    required PlantModel plant,
    required double heightCm,
    String? note,
    String? photoPath,
  });

  /// Updates today's height task log without re-awarding XP.
  Future<Result<void>> updateHeightTask({
    required PlantModel plant,
    required double heightCm,
    String? note,
    String? photoPath,
  });

  /// Completes routine task (e.g. 'siram', 'bersih_bersih'), awards XP, and updates streak.
  Future<Result<void>> completeRoutineTask({
    required PlantModel plant,
    required String taskType,
    String? notes,
  });

  /// Completes a cyclic schedule task item.
  Future<Result<void>> completeCyclicTask(DueScheduleItem item);

  /// Retrieves chronological care history logs.
  Future<Result<List<CareHistoryItem>>> getCareHistory({
    String? userId,
    String? userPlantId,
  });

  /// Returns today's active task types for a specific user plant.
  Future<Result<List<String>>> getTodaysTaskTypes(String userPlantId);

  /// Returns the latest recorded height for a plant.
  Future<Result<double>> getLatestRecordedHeight(String userPlantId);

  /// Returns logged height today if already recorded.
  Future<Result<double?>> getLoggedHeightToday(String userPlantId);

  /// Returns logged photo path today if recorded.
  Future<Result<String?>> getLoggedPhotoToday(String userPlantId);

  /// Returns logged note today if recorded.
  Future<Result<String?>> getLoggedNoteToday(String userPlantId);

  /// Returns total XP accumulated by the user.
  Future<Result<int>> getTotalUserXp([String? userId]);

  /// Checks if all daily tasks are completed today for user.
  Future<Result<bool>> isAllTasksCompleteTodayForUser(String userId);

  /// Updates an individual growth log entry.
  Future<Result<void>> updateGrowthLog({
    required String logId,
    required String userPlantId,
    required double heightCm,
    String? note,
    String? photoPath,
  });
}
