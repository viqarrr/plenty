import 'package:flutter/foundation.dart';

/// Data Model representing care schedules for routine tasks (watering, cleaning, height monitoring).
@immutable
class CareScheduleModel {
  final String id;
  final String userPlantId;
  final String taskType;
  final int? intervalDays;
  final DateTime? lastPerformedAt;
  final DateTime? nextDueDate;
  final bool isActive;

  const CareScheduleModel({
    required this.id,
    required this.userPlantId,
    required this.taskType,
    this.intervalDays,
    this.lastPerformedAt,
    this.nextDueDate,
    this.isActive = true,
  });

  factory CareScheduleModel.fromMap(Map<String, dynamic> map) => CareScheduleModel(
        id: map['id'] as String,
        userPlantId: map['user_plant_id'] as String,
        taskType: map['task_type'] as String,
        intervalDays: map['interval_days'] as int?,
        lastPerformedAt: map['last_performed_at'] != null
            ? DateTime.tryParse(map['last_performed_at'] as String)
            : null,
        nextDueDate: map['next_due_date'] != null
            ? DateTime.tryParse(map['next_due_date'] as String)
            : null,
        isActive: (map['is_active'] as int? ?? 1) == 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_plant_id': userPlantId,
        'task_type': taskType,
        'interval_days': intervalDays,
        'last_performed_at': lastPerformedAt?.toIso8601String(),
        'next_due_date': nextDueDate?.toIso8601String(),
        'is_active': isActive ? 1 : 0,
      };

  factory CareScheduleModel.fromJson(Map<String, dynamic> json) =>
      CareScheduleModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  CareScheduleModel copyWith({
    String? id,
    String? userPlantId,
    String? taskType,
    int? intervalDays,
    DateTime? lastPerformedAt,
    DateTime? nextDueDate,
    bool? isActive,
  }) {
    return CareScheduleModel(
      id: id ?? this.id,
      userPlantId: userPlantId ?? this.userPlantId,
      taskType: taskType ?? this.taskType,
      intervalDays: intervalDays ?? this.intervalDays,
      lastPerformedAt: lastPerformedAt ?? this.lastPerformedAt,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CareScheduleModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
