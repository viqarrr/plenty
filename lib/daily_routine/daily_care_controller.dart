import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plenty/data/datasources/preference_handler.dart';
import 'package:plenty/data/models/plant_model.dart';
import 'package:plenty/data/repositories/care_repository.dart';
import 'package:plenty/data/repositories/plant_repository.dart';
import 'package:plenty/data/repositories/streak_repository.dart';

/// Item representing a plant's mandatory daily growth height log.
@immutable
class DailyHeightLogItem {
  final PlantModel plant;
  final double lastRecordedHeight;
  final bool isCompletedToday;
  final double? loggedHeightToday;
  final bool isPhotoDue;
  final String? loggedPhotoPathToday;
  final String? loggedNoteToday;

  const DailyHeightLogItem({
    required this.plant,
    required this.lastRecordedHeight,
    required this.isCompletedToday,
    this.loggedHeightToday,
    this.isPhotoDue = false,
    this.loggedPhotoPathToday,
    this.loggedNoteToday,
  });

  DailyHeightLogItem copyWith({
    PlantModel? plant,
    double? lastRecordedHeight,
    bool? isCompletedToday,
    double? loggedHeightToday,
    bool? isPhotoDue,
    String? loggedPhotoPathToday,
    String? loggedNoteToday,
  }) {
    return DailyHeightLogItem(
      plant: plant ?? this.plant,
      lastRecordedHeight: lastRecordedHeight ?? this.lastRecordedHeight,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      loggedHeightToday: loggedHeightToday ?? this.loggedHeightToday,
      isPhotoDue: isPhotoDue ?? this.isPhotoDue,
      loggedPhotoPathToday: loggedPhotoPathToday ?? this.loggedPhotoPathToday,
      loggedNoteToday: loggedNoteToday ?? this.loggedNoteToday,
    );
  }
}

/// Item representing a plant's cyclic scheduled care task (e.g. watering, leaf cleaning).
@immutable
class DueScheduleItem {
  final PlantModel plant;
  final String taskType; // 'siram', 'bersih_bersih'
  final String title;
  final String subtitle;
  final bool isCompletedToday;
  final int xpAward;

  const DueScheduleItem({
    required this.plant,
    required this.taskType,
    required this.title,
    required this.subtitle,
    required this.isCompletedToday,
    required this.xpAward,
  });

  DueScheduleItem copyWith({
    PlantModel? plant,
    String? taskType,
    String? title,
    String? subtitle,
    bool? isCompletedToday,
    int? xpAward,
  }) {
    return DueScheduleItem(
      plant: plant ?? this.plant,
      taskType: taskType ?? this.taskType,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      xpAward: xpAward ?? this.xpAward,
    );
  }
}

/// State for the Daily Care Routine screen.
@immutable
class DailyCareState {
  final List<DailyHeightLogItem> heightLogs;
  final List<DueScheduleItem> dueSchedules;
  final int streakCount;
  final bool isLoading;
  final String? errorMessage;

  const DailyCareState({
    this.heightLogs = const [],
    this.dueSchedules = const [],
    this.streakCount = 1,
    this.isLoading = false,
    this.errorMessage,
  });

  int get totalTasksCount => heightLogs.length + dueSchedules.length;

  int get completedTasksCount {
    final completedHeight = heightLogs.where((l) => l.isCompletedToday).length;
    final completedSchedules =
        dueSchedules.where((s) => s.isCompletedToday).length;
    return completedHeight + completedSchedules;
  }

  double get progressRatio =>
      totalTasksCount > 0 ? (completedTasksCount / totalTasksCount).clamp(0.0, 1.0) : 1.0;

  DailyCareState copyWith({
    List<DailyHeightLogItem>? heightLogs,
    List<DueScheduleItem>? dueSchedules,
    int? streakCount,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DailyCareState(
      heightLogs: heightLogs ?? this.heightLogs,
      dueSchedules: dueSchedules ?? this.dueSchedules,
      streakCount: streakCount ?? this.streakCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final dailyCareControllerProvider =
    StateNotifierProvider.autoDispose<DailyCareController, DailyCareState>((ref) {
  return DailyCareController();
});

/// Riverpod Controller managing Today's Care routine checklist and atomic logging.
class DailyCareController extends StateNotifier<DailyCareState> {
  final PlantRepository _plantRepo;
  final CareRepository _careRepo;
  final StreakRepository _streakRepo;

  DailyCareController({
    PlantRepository? plantRepo,
    CareRepository? careRepo,
    StreakRepository? streakRepo,
  })  : _plantRepo = plantRepo ?? PlantRepository(),
        _careRepo = careRepo ?? CareRepository(),
        _streakRepo = streakRepo ?? StreakRepository(),
        super(const DailyCareState(isLoading: true)) {
    loadTodayCare();
  }

  Future<void> loadTodayCare() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = await PreferenceHandler.getUser();
      final userId = (user?.id != null && user!.id! > 0)
          ? user.id.toString()
          : '1';

      final plants = await _plantRepo.getUserPlants(userId);
      final streak = await _streakRepo.getStreak(userId);

      final heightLogs = <DailyHeightLogItem>[];
      final dueSchedules = <DueScheduleItem>[];

      for (final plant in plants) {
        // 1. Mandatory height log item
        final lastHeight = await _careRepo.getLatestRecordedHeight(plant.id);
        final loggedToday = await _careRepo.getLoggedHeightToday(plant.id);
        final isPhotoDue = await _careRepo.isPhotoDueForPlant(plant.id, cycleDays: 3);
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

      if (!mounted) return;
      state = state.copyWith(
        heightLogs: heightLogs,
        dueSchedules: dueSchedules,
        streakCount: streak.currentStreak,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat rutinitas perawatan hari ini: $e',
      );
    }
  }

  /// Atomically logs height measurement (+15 XP) and refreshes routine state.
  Future<void> completeHeightTask({
    required PlantModel plant,
    required double heightCm,
    String? note,
    String? photoPath,
  }) async {
    try {
      await _careRepo.completeHeightTask(
        userPlantId: plant.id,
        heightCm: heightCm,
        note: note,
        photoPath: photoPath,
      );
      await loadTodayCare();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: 'Gagal mencatat tinggi: $e');
    }
  }

  /// Updates today's growth log (height, note, photo) without re-awarding XP and refreshes routine state.
  Future<void> updateHeightTask({
    required PlantModel plant,
    required double heightCm,
    String? note,
    String? photoPath,
  }) async {
    try {
      await _careRepo.updateHeightTask(
        userPlantId: plant.id,
        heightCm: heightCm,
        note: note,
        photoPath: photoPath,
      );
      await loadTodayCare();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: 'Gagal memperbarui log pertumbuhan: $e');
    }
  }

  /// Atomically completes a cyclic care task (+10 XP) and refreshes routine state.
  Future<void> completeCyclicTask(DueScheduleItem item) async {
    try {
      await _careRepo.completeRoutineTask(
        userPlantId: item.plant.id,
        taskType: item.taskType,
      );
      await loadTodayCare();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: 'Gagal menyelesaikan tugas: $e');
    }
  }
}
