import 'package:flutter/foundation.dart';

/// Data Model representing a single completed care action for the history view.
@immutable
class CareHistoryItem {
  final String id;
  final String userPlantId;
  final String plantNickname;
  final String taskType;
  final String activityDetail;
  final DateTime completedAt;
  final String logDate;
  final int xpAwarded;
  final String? notes;
  final String? photoPath;

  const CareHistoryItem({
    required this.id,
    required this.userPlantId,
    required this.plantNickname,
    required this.taskType,
    required this.activityDetail,
    required this.completedAt,
    required this.logDate,
    required this.xpAwarded,
    this.notes,
    this.photoPath,
  });

  factory CareHistoryItem.fromMap(Map<String, dynamic> map) {
    final taskType = map['task_type'] as String? ?? 'siram';
    final plantNickname = map['plant_nickname'] as String? ?? 'Plant';
    final notes = map['notes'] as String?;
    final loggedHeight = (map['logged_height'] as num?)?.toDouble();
    final photoPath = map['photo_path'] as String? ?? map['logged_photo_path'] as String?;

    String detail;
    if (taskType == 'monitor_tinggi') {
      detail = loggedHeight != null
          ? 'Tinggi dicatat: ${loggedHeight.toStringAsFixed(1)} cm'
          : (notes != null && notes.isNotEmpty
              ? 'Tinggi dicatat: $notes'
              : 'Tinggi dicatat');
    } else if (taskType == 'siram') {
      detail = notes != null && notes.isNotEmpty
          ? 'Disiram $notes'
          : 'Disiram 250ml';
    } else if (taskType == 'bersih_bersih') {
      detail = notes != null && notes.isNotEmpty
          ? 'Daun dibersihkan: $notes'
          : 'Daun dibersihkan';
    } else {
      detail = notes ?? 'Perawatan selesai';
    }

    return CareHistoryItem(
      id: map['log_id'] as String? ?? map['id'] as String? ?? '',
      userPlantId: map['user_plant_id'] as String? ?? '',
      plantNickname: plantNickname,
      taskType: taskType,
      activityDetail: detail,
      completedAt: DateTime.tryParse(map['completed_at'] as String? ?? '') ??
          DateTime.now(),
      logDate: map['log_date'] as String? ?? '',
      xpAwarded: map['xp_awarded'] as int? ?? 10,
      notes: notes,
      photoPath: photoPath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CareHistoryItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
