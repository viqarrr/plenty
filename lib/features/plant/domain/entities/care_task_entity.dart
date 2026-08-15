import 'package:flutter/material.dart';
import 'package:plenty/features/plant/domain/entities/plant_entity.dart';

/// Care task type for watering or cleaning routine.
enum TaskType {
  watering,
  cleaning;

  String get label => switch (this) {
    TaskType.watering => 'Penyiraman',
    TaskType.cleaning => 'Kebersihan',
  };

  String get action => switch (this) {
    TaskType.watering => 'Siram',
    TaskType.cleaning => 'Bersihkan',
  };

  IconData get icon => switch (this) {
    TaskType.watering => Icons.water_drop,
    TaskType.cleaning => Icons.cleaning_services,
  };

  Color get color => switch (this) {
    TaskType.watering => Colors.blue,
    TaskType.cleaning => Colors.orange,
  };
}

/// Domain Entity representing an actionable care task.
@immutable
class CareTaskEntity {
  final PlantEntity plant;
  final TaskType type;
  final String description;

  const CareTaskEntity({
    required this.plant,
    required this.type,
    required this.description,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CareTaskEntity &&
          runtimeType == other.runtimeType &&
          plant.id == other.plant.id &&
          type == other.type;

  @override
  int get hashCode => plant.id.hashCode ^ type.hashCode;
}
