import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/daily_care/domain/models/care_history_item.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';
import 'package:plenty/features/daily_care/data/care_repository.dart';
import 'package:plenty/features/garden/data/repositories/plant_repository.dart';
import 'package:plenty/features/garden/data/repositories/streak_repository.dart';
import 'package:plenty/features/daily_care/domain/models/daily_care_state.dart';

/// Data Aggregator & Repository for Daily Care routines.
/// Handles batch queries, atomic logging transactions, and streak synchronization.
class DailyCareRepository {
  final PlantRepository _plantRepo;
  final CareRepository _careRepo;
  final StreakRepository _streakRepo;

  DailyCareRepository({
    PlantRepository? plantRepo,
    CareRepository? careRepo,
    StreakRepository? streakRepo,
    DatabaseHelper? dbHelper,
  })  : _plantRepo = plantRepo ?? PlantRepository(dbHelper: dbHelper),
        _careRepo = careRepo ?? CareRepository(dbHelper: dbHelper),
        _streakRepo = streakRepo ?? StreakRepository(dbHelper: dbHelper);

  Future<DailyCareState> loadDailyCareData({String? explicitUserId}) async {
    final user = await PreferenceHandler.getUser();
    final userId = explicitUserId ??
        ((user?.id != null && user!.id! > 0) ? user.id.toString() : '1');

    final plants = await _plantRepo.getUserPlants(userId);
    final streak = await _streakRepo.getStreak(userId);

    final heightLogs = <DailyHeightLogItem>[];
    final dueSchedules = <DueScheduleItem>[];

    for (final plant in plants) {
      // 1. Mandatory height log item
      final lastHeight = await _careRepo.getLatestRecordedHeight(plant.id);
      final loggedToday = await _careRepo.getLoggedHeightToday(plant.id);
      final isPhotoDue =
          await _careRepo.isPhotoDueForPlant(plant.id, cycleDays: 3);
      final loggedPhotoToday = await _careRepo.getLoggedPhotoToday(plant.id);
      final loggedNoteToday = await _careRepo.getLoggedNoteToday(plant.id);

      heightLogs.add(
        DailyHeightLogItem(
          plant: plant,
          lastRecordedHeight: lastHeight,
          isCompletedToday: loggedToday != null,
          loggedHeightToday: loggedToday,
          isPhotoDue: isPhotoDue,
          loggedPhotoPathToday: loggedPhotoToday,
          loggedNoteToday: loggedNoteToday,
        ),
      );

      // 2. Cyclic task schedules
      final dueTaskTypes = await _careRepo.getTodaysTaskTypes(plant.id);

      if (dueTaskTypes.contains('siram')) {
        dueSchedules.add(
          DueScheduleItem(
            plant: plant,
            taskType: 'siram',
            title: 'Penyiraman',
            subtitle: 'Siram 250ml air',
            isCompletedToday: false,
            xpAward: 10,
          ),
        );
      }

      if (dueTaskTypes.contains('bersih_bersih')) {
        dueSchedules.add(
          DueScheduleItem(
            plant: plant,
            taskType: 'bersih_bersih',
            title: 'Bersihkan Daun',
            subtitle: 'Bersihkan debu daun',
            isCompletedToday: false,
            xpAward: 10,
          ),
        );
      }
    }

    return DailyCareState(
      heightLogs: heightLogs,
      dueSchedules: dueSchedules,
      streakCount: streak.currentStreak,
      isLoading: false,
    );
  }

  Future<void> completeHeightTask({
    required PlantModel plant,
    required double heightCm,
    String? note,
    String? photoPath,
  }) async {
    await _careRepo.completeHeightTask(
      userPlantId: plant.id,
      heightCm: heightCm,
      note: note,
      photoPath: photoPath,
    );
    await _syncStreak(plant.userId);
  }

  Future<void> updateHeightTask({
    required PlantModel plant,
    required double heightCm,
    String? note,
    String? photoPath,
  }) async {
    await _careRepo.updateHeightTask(
      userPlantId: plant.id,
      heightCm: heightCm,
      note: note,
      photoPath: photoPath,
    );
    await _syncStreak(plant.userId);
  }

  Future<void> completeRoutineTask({
    required PlantModel plant,
    required String taskType,
  }) async {
    await _careRepo.completeRoutineTask(
      userPlantId: plant.id,
      taskType: taskType,
    );
    await _syncStreak(plant.userId);
  }

  Future<List<CareHistoryItem>> getCareHistory({String? userId}) async {
    final effectiveUserId = userId ?? '1';
    return _careRepo.getCareHistory(userId: effectiveUserId);
  }

  Future<void> _syncStreak(String userId) async {
    try {
      await _streakRepo.evaluateDailyStreak(userId);
    } catch (_) {}
  }
}
