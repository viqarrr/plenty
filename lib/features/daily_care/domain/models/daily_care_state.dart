import 'package:flutter/foundation.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';

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

  bool get hasNoTasksScheduled => totalTasksCount == 0;

  bool get isAllCompleted =>
      totalTasksCount > 0 && completedTasksCount == totalTasksCount;

  int get remainingTasksCount => totalTasksCount - completedTasksCount;

  double get progressRatio => totalTasksCount > 0
      ? (completedTasksCount / totalTasksCount).clamp(0.0, 1.0)
      : 0.0;

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
