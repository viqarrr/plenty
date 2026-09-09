import 'package:flutter/foundation.dart';

/// Draft object used during plant setup or details modal when creating a time capsule.
@immutable
class TimeCapsuleDraft {
  final String photoPath;
  final String? note;
  final DateTime unlockAt;

  TimeCapsuleDraft({
    String? photoPath,
    String? note,
    String? message,
    DateTime? unlockAt,
    int? durationMonths,
  })  : photoPath = photoPath ?? '',
        note = note ?? message,
        unlockAt = unlockAt ??
            DateTime.now().add(
              Duration(days: (durationMonths ?? 3) * 30),
            );

  String get message => note ?? '';
  int get durationMonths {
    final diff = unlockAt.difference(DateTime.now()).inDays;
    return diff > 0 ? (diff / 30).round() : 0;
  }
}

/// Data Model representing a stored Time Capsule entry for a plant.
@immutable
class TimeCapsuleModel {
  final String id;
  final String userPlantId;
  final String photoPath;
  final String? note;
  final DateTime createdAt;
  final DateTime unlockAt;
  final bool isUnlocked;

  const TimeCapsuleModel({
    required this.id,
    required this.userPlantId,
    required this.photoPath,
    this.note,
    required this.createdAt,
    required this.unlockAt,
    this.isUnlocked = false,
  });

  String get message => note ?? '';

  factory TimeCapsuleModel.fromMap(Map<String, dynamic> map) =>
      TimeCapsuleModel(
        id: map['id'] as String,
        userPlantId: map['user_plant_id'] as String,
        photoPath: (map['photo_path'] as String?) ?? '',
        note: map['note'] as String?,
        createdAt:
            DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now(),
        unlockAt:
            DateTime.tryParse(map['unlock_at'].toString()) ?? DateTime.now(),
        isUnlocked: map['is_unlocked'] is bool
            ? (map['is_unlocked'] as bool)
            : ((map['is_unlocked'] as int? ?? 0) == 1),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_plant_id': userPlantId,
        'photo_path': photoPath,
        'note': note,
        'created_at': createdAt.toIso8601String(),
        'unlock_at': unlockAt.toIso8601String(),
        'is_unlocked': isUnlocked ? 1 : 0,
      };

  Map<String, dynamic> toFirestoreMap() => {
        'id': id,
        'user_plant_id': userPlantId,
        'photo_path': photoPath,
        'note': note,
        'created_at': createdAt.toIso8601String(),
        'unlock_at': unlockAt.toIso8601String(),
        'is_unlocked': isUnlocked,
      };

  TimeCapsuleModel copyWith({
    String? id,
    String? userPlantId,
    String? photoPath,
    String? note,
    DateTime? createdAt,
    DateTime? unlockAt,
    bool? isUnlocked,
  }) {
    return TimeCapsuleModel(
      id: id ?? this.id,
      userPlantId: userPlantId ?? this.userPlantId,
      photoPath: photoPath ?? this.photoPath,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      unlockAt: unlockAt ?? this.unlockAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  factory TimeCapsuleModel.fromJson(Map<String, dynamic> json) =>
      TimeCapsuleModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeCapsuleModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
