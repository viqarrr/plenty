import 'package:flutter/foundation.dart';

/// Domain Entity representing a Plant and its botanical & care profile.
@immutable
class PlantEntity {
  final String id;
  final String name;
  final String scientificName;
  final String location; // Indoor, Outdoor
  final String containerDetail;
  final String lightIntensity;
  final String distanceFromWindow;
  final String specificArea; // Ruang Tamu, Dapur, etc.
  final String imageAsset;
  final String careLevel; // EASY CARE, MEDIUM CARE, etc.
  final String waterSchedule;
  final String lightSchedule;
  final String toxicity;
  final String description;
  final String maxHeight;
  final String growthRate;
  final String growthCycle;
  final String pruningSeason;
  final String flowerStatus;
  final String pests;
  final bool isCustom;
  final String timeCapsuleMessage;
  final bool hasTimeCapsule;
  final String nextWaterDate;
  final String lastCleanedDate;

  const PlantEntity({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.location,
    required this.containerDetail,
    required this.lightIntensity,
    required this.distanceFromWindow,
    required this.specificArea,
    required this.imageAsset,
    required this.careLevel,
    required this.waterSchedule,
    required this.lightSchedule,
    required this.toxicity,
    required this.description,
    required this.maxHeight,
    required this.growthRate,
    required this.growthCycle,
    required this.pruningSeason,
    required this.flowerStatus,
    required this.pests,
    this.isCustom = false,
    this.timeCapsuleMessage = '',
    this.hasTimeCapsule = false,
    required this.nextWaterDate,
    required this.lastCleanedDate,
  });

  PlantEntity copyWith({
    String? id,
    String? name,
    String? scientificName,
    String? location,
    String? containerDetail,
    String? lightIntensity,
    String? distanceFromWindow,
    String? specificArea,
    String? imageAsset,
    String? careLevel,
    String? waterSchedule,
    String? lightSchedule,
    String? toxicity,
    String? description,
    String? maxHeight,
    String? growthRate,
    String? growthCycle,
    String? pruningSeason,
    String? flowerStatus,
    String? pests,
    bool? isCustom,
    String? timeCapsuleMessage,
    bool? hasTimeCapsule,
    String? nextWaterDate,
    String? lastCleanedDate,
  }) {
    return PlantEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      location: location ?? this.location,
      containerDetail: containerDetail ?? this.containerDetail,
      lightIntensity: lightIntensity ?? this.lightIntensity,
      distanceFromWindow: distanceFromWindow ?? this.distanceFromWindow,
      specificArea: specificArea ?? this.specificArea,
      imageAsset: imageAsset ?? this.imageAsset,
      careLevel: careLevel ?? this.careLevel,
      waterSchedule: waterSchedule ?? this.waterSchedule,
      lightSchedule: lightSchedule ?? this.lightSchedule,
      toxicity: toxicity ?? this.toxicity,
      description: description ?? this.description,
      maxHeight: maxHeight ?? this.maxHeight,
      growthRate: growthRate ?? this.growthRate,
      growthCycle: growthCycle ?? this.growthCycle,
      pruningSeason: pruningSeason ?? this.pruningSeason,
      flowerStatus: flowerStatus ?? this.flowerStatus,
      pests: pests ?? this.pests,
      isCustom: isCustom ?? this.isCustom,
      timeCapsuleMessage: timeCapsuleMessage ?? this.timeCapsuleMessage,
      hasTimeCapsule: hasTimeCapsule ?? this.hasTimeCapsule,
      nextWaterDate: nextWaterDate ?? this.nextWaterDate,
      lastCleanedDate: lastCleanedDate ?? this.lastCleanedDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlantEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
