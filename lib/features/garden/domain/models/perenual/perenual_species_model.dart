import 'package:flutter/foundation.dart';
import 'package:plenty/features/plant_catalog/domain/models/plant_catalog_model.dart';

/// DTO representing a plant item returned from the Perenual `/species-list` API.
@immutable
class PerenualSpeciesModel {
  final int id;
  final String commonName;
  final List<String> scientificName;
  final List<String> otherName;
  final String? family;
  final String? cycle;
  final String? watering;
  final List<String> sunlight;
  final String? defaultImageUrl;
  final String? defaultImageThumbnail;

  const PerenualSpeciesModel({
    required this.id,
    required this.commonName,
    this.scientificName = const [],
    this.otherName = const [],
    this.family,
    this.cycle,
    this.watering,
    this.sunlight = const [],
    this.defaultImageUrl,
    this.defaultImageThumbnail,
  });

  factory PerenualSpeciesModel.fromJson(Map<String, dynamic> json) {
    final rawSci = json['scientific_name'];
    final List<String> sciNames = switch (rawSci) {
      List list => list.map((e) => e.toString()).toList(),
      String s when s.isNotEmpty => [s],
      _ => const [],
    };

    final rawOther = json['other_name'];
    final List<String> otherNames = switch (rawOther) {
      List list => list.map((e) => e.toString()).toList(),
      String s when s.isNotEmpty => [s],
      _ => const [],
    };

    final rawSunlight = json['sunlight'];
    final List<String> sunlightList = switch (rawSunlight) {
      List list => list.map((e) => e.toString()).toList(),
      String s when s.isNotEmpty => [s],
      _ => const [],
    };

    String? imgUrl;
    String? thumbUrl;
    final rawImage = json['default_image'];
    if (rawImage is Map<String, dynamic>) {
      imgUrl = (rawImage['regular_url'] ??
              rawImage['original_url'] ??
              rawImage['medium_url'] ??
              rawImage['small_url'] ??
              rawImage['thumbnail'])
          ?.toString();
      thumbUrl = (rawImage['thumbnail'] ?? imgUrl)?.toString();
    }

    return PerenualSpeciesModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      commonName: (json['common_name'] as String?)?.trim() ?? '',
      scientificName: sciNames,
      otherName: otherNames,
      family: json['family'] as String?,
      cycle: json['cycle'] as String?,
      watering: json['watering'] as String?,
      sunlight: sunlightList,
      defaultImageUrl: imgUrl,
      defaultImageThumbnail: thumbUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'common_name': commonName,
        'scientific_name': scientificName,
        'other_name': otherName,
        'family': family,
        'cycle': cycle,
        'watering': watering,
        'sunlight': sunlight,
        'default_image': defaultImageUrl != null
            ? {
                'regular_url': defaultImageUrl,
                'thumbnail': defaultImageThumbnail,
              }
            : null,
      };

  int get wateringIntervalDays {
    final w = (watering ?? '').toLowerCase();
    if (w.contains('frequent')) return 3;
    if (w.contains('average')) return 7;
    if (w.contains('minimum')) return 14;
    if (w.contains('none')) return 21;
    return 7;
  }

  String get sunlightDisplay {
    if (sunlight.isEmpty) return 'Sinar Tidak Langsung Sedang';
    return sunlight.join(', ');
  }

  String get careLevelDisplay {
    final w = (watering ?? '').toLowerCase();
    if (w.contains('minimum') || w.contains('none')) return 'EASY CARE';
    if (w.contains('frequent')) return 'INTERMEDIATE';
    return 'EASY CARE';
  }

  PlantCatalogModel toPlantCatalogModel() {
    final displayName = commonName.isNotEmpty
        ? commonName
        : (scientificName.isNotEmpty ? scientificName.first : 'Tanaman Hias');

    return PlantCatalogModel(
      id: 'perenual_$id',
      commonName: displayName,
      scientificName: scientificName.isNotEmpty ? scientificName.first : null,
      family: family,
      defaultWateringInterval: wateringIntervalDays,
      sunlightLevel: sunlightDisplay,
      careLevel: careLevelDisplay,
      imageUrl: defaultImageUrl,
      localImagePath: null,
      cycle: cycle,
      cachedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerenualSpeciesModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PerenualSpeciesModel(id: $id, commonName: $commonName, scientificName: $scientificName)';
}
