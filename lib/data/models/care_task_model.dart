import 'package:flutter/foundation.dart';
import 'package:plenty/core/constants/task_types.dart';
import 'package:plenty/data/models/plant_model.dart';

export 'package:plenty/core/constants/task_types.dart';

/// Consolidated Data Model representing an actionable care task.
@immutable
class CareTaskModel {
  final PlantModel plant;
  final TaskType type;
  final String description;

  const CareTaskModel({
    required this.plant,
    required this.type,
    required this.description,
    String? id,
    String? userPlantId,
  });

  String get id => '${plant.id}_${type.id}';
  String get userPlantId => plant.id;

  CareTaskModel copyWith({
    PlantModel? plant,
    TaskType? type,
    String? description,
  }) {
    return CareTaskModel(
      plant: plant ?? this.plant,
      type: type ?? this.type,
      description: description ?? this.description,
    );
  }

  factory CareTaskModel.fromMap(Map<String, dynamic> map) {
    return CareTaskModel(
      plant: PlantModel.fromMap(map['plant'] as Map<String, dynamic>),
      type: TaskType.fromId(map['type'] as String? ?? 'siram'),
      description: (map['description'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'plant': plant.toMap(),
      'type': type.id,
      'description': description,
    };
  }

  factory CareTaskModel.fromJson(Map<String, dynamic> json) =>
      CareTaskModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CareTaskModel &&
          runtimeType == other.runtimeType &&
          plant.id == other.plant.id &&
          type == other.type;

  @override
  int get hashCode => plant.id.hashCode ^ type.hashCode;

  @override
  String toString() =>
      'CareTaskModel(plant: ${plant.nickname}, type: ${type.id}, description: $description)';
}
