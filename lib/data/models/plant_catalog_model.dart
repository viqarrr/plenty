import 'package:flutter/foundation.dart';

/// Data Model representing botanical plant species catalog information.
@immutable
class PlantCatalogModel {
  final String id;
  final String commonName;
  final String? scientificName;
  final String? family;
  final int defaultWateringInterval;
  final String? sunlightLevel;
  final String? careLevel;
  final String? imageUrl;
  final String? localImagePath;
  final DateTime cachedAt;

  const PlantCatalogModel({
    required this.id,
    required this.commonName,
    this.scientificName,
    this.family,
    this.defaultWateringInterval = 3,
    this.sunlightLevel,
    this.careLevel,
    this.imageUrl,
    this.localImagePath,
    required this.cachedAt,
  });

  factory PlantCatalogModel.fromMap(Map<String, dynamic> map) => PlantCatalogModel(
        id: map['id'] as String,
        commonName: map['common_name'] as String,
        scientificName: map['scientific_name'] as String?,
        family: map['family'] as String?,
        defaultWateringInterval: map['default_watering_interval'] as int? ?? 3,
        sunlightLevel: map['sunlight_level'] as String?,
        careLevel: map['care_level'] as String?,
        imageUrl: map['image_url'] as String?,
        localImagePath: map['local_image_path'] as String?,
        cachedAt: map['cached_at'] != null
            ? (DateTime.tryParse(map['cached_at'].toString()) ?? DateTime.now())
            : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'common_name': commonName,
        'scientific_name': scientificName,
        'family': family,
        'default_watering_interval': defaultWateringInterval,
        'sunlight_level': sunlightLevel,
        'care_level': careLevel,
        'image_url': imageUrl,
        'local_image_path': localImagePath,
        'cached_at': cachedAt.toIso8601String(),
      };

  factory PlantCatalogModel.fromJson(Map<String, dynamic> json) =>
      PlantCatalogModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlantCatalogModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
