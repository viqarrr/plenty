import 'package:flutter/foundation.dart';

/// Data Model representing completed care actions audit log.
@immutable
class CareActionLogModel {
  final String id;
  final String userPlantId;
  final String taskType;
  final DateTime completedAt;
  final String logDate;
  final int xpAwarded;
  final String? notes;

  const CareActionLogModel({
    required this.id,
    required this.userPlantId,
    required this.taskType,
    required this.completedAt,
    required this.logDate,
    this.xpAwarded = 0,
    this.notes,
  });

  factory CareActionLogModel.fromMap(Map<String, dynamic> map) => CareActionLogModel(
        id: map['id'] as String,
        userPlantId: map['user_plant_id'] as String,
        taskType: map['task_type'] as String,
        completedAt: DateTime.parse(map['completed_at'] as String),
        logDate: map['log_date'] as String,
        xpAwarded: map['xp_awarded'] as int? ?? 0,
        notes: map['notes'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_plant_id': userPlantId,
        'task_type': taskType,
        'completed_at': completedAt.toIso8601String(),
        'log_date': logDate,
        'xp_awarded': xpAwarded,
        'notes': notes,
      };

  factory CareActionLogModel.fromJson(Map<String, dynamic> json) =>
      CareActionLogModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CareActionLogModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
