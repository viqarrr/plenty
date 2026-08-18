import 'package:flutter/foundation.dart';

/// Data Model representing growth tracking entries and historical height snapshots.
@immutable
class GrowthLogModel {
  final String id;
  final String userPlantId;
  final String? photoPath;
  final double? heightCm;
  final int? leafCount;
  final String? note;
  final String source;
  final DateTime loggedAt;

  const GrowthLogModel({
    required this.id,
    required this.userPlantId,
    this.photoPath,
    this.heightCm,
    this.leafCount,
    this.note,
    this.source = 'manual',
    required this.loggedAt,
  });

  factory GrowthLogModel.fromMap(Map<String, dynamic> map) => GrowthLogModel(
        id: map['id'] as String,
        userPlantId: map['user_plant_id'] as String,
        photoPath: map['photo_path'] as String?,
        heightCm: (map['height_cm'] as num?)?.toDouble(),
        leafCount: map['leaf_count'] as int?,
        note: map['note'] as String?,
        source: map['source'] as String? ?? 'manual',
        loggedAt: DateTime.parse(map['logged_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_plant_id': userPlantId,
        'photo_path': photoPath,
        'height_cm': heightCm,
        'leaf_count': leafCount,
        'note': note,
        'source': source,
        'logged_at': loggedAt.toIso8601String(),
      };

  factory GrowthLogModel.fromJson(Map<String, dynamic> json) =>
      GrowthLogModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  GrowthLogModel copyWith({
    String? id,
    String? userPlantId,
    String? photoPath,
    double? heightCm,
    int? leafCount,
    String? note,
    String? source,
    DateTime? loggedAt,
  }) {
    return GrowthLogModel(
      id: id ?? this.id,
      userPlantId: userPlantId ?? this.userPlantId,
      photoPath: photoPath ?? this.photoPath,
      heightCm: heightCm ?? this.heightCm,
      leafCount: leafCount ?? this.leafCount,
      note: note ?? this.note,
      source: source ?? this.source,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GrowthLogModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'GrowthLogModel(id: $id, userPlantId: $userPlantId, heightCm: $heightCm, source: $source)';
}
