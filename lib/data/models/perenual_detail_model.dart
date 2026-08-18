import 'package:flutter/foundation.dart';
import 'package:plenty/data/models/plant_catalog_model.dart';

/// DTO representing comprehensive botanical details returned from Perenual `/species/details/{id}`.
@immutable
class PerenualDetailModel {
  final int id;
  final String commonName;
  final List<String> scientificName;
  final List<String> otherName;
  final String? family;
  final List<String> origin;
  final List<String> soil;
  final String? type;
  final String? dimension;
  final String? cycle;
  final String? watering;
  final String? wateringGeneralBenchmarkValue;
  final String? wateringGeneralBenchmarkUnit;
  final List<String> sunlight;
  final String? careLevel;
  final String? maintenance;
  final String? growthRate;
  final bool poisonousToHumans;
  final bool poisonousToPets;
  final String? description;
  final String? defaultImageUrl;
  final String? defaultImageThumbnail;

  const PerenualDetailModel({
    required this.id,
    required this.commonName,
    this.scientificName = const [],
    this.otherName = const [],
    this.family,
    this.origin = const [],
    this.soil = const [],
    this.type,
    this.dimension,
    this.cycle,
    this.watering,
    this.wateringGeneralBenchmarkValue,
    this.wateringGeneralBenchmarkUnit,
    this.sunlight = const [],
    this.careLevel,
    this.maintenance,
    this.growthRate,
    this.poisonousToHumans = false,
    this.poisonousToPets = false,
    this.description,
    this.defaultImageUrl,
    this.defaultImageThumbnail,
  });

  factory PerenualDetailModel.fromJson(Map<String, dynamic> json) {
    // Defensively parse scientific_name
    final rawSci = json['scientific_name'];
    final List<String> sciNames = switch (rawSci) {
      List list => list.map((e) => e.toString()).toList(),
      String s when s.isNotEmpty => [s],
      _ => const [],
    };

    // Defensively parse other_name
    final rawOther = json['other_name'];
    final List<String> otherNames = switch (rawOther) {
      List list => list.map((e) => e.toString()).toList(),
      String s when s.isNotEmpty => [s],
      _ => const [],
    };

    // Defensively parse origin
    final rawOrigin = json['origin'];
    final List<String> originList = switch (rawOrigin) {
      List list => list.map((e) => e.toString()).toList(),
      String s when s.isNotEmpty => [s],
      _ => const [],
    };

    // Defensively parse sunlight
    final rawSunlight = json['sunlight'];
    final List<String> sunlightList = switch (rawSunlight) {
      List list => list.map((e) => e.toString()).toList(),
      String s when s.isNotEmpty => [s],
      _ => const [],
    };

    // Defensively parse soil
    final rawSoil = json['soil'];
    final List<String> soilList = switch (rawSoil) {
      List list => list.map((e) => e.toString()).toList(),
      String s when s.isNotEmpty => [s],
      _ => const [],
    };

    // Defensively parse watering benchmark
    String? benchVal;
    String? benchUnit;
    final rawBench = json['watering_general_benchmark'];
    if (rawBench is Map<String, dynamic>) {
      benchVal = rawBench['value']?.toString();
      benchUnit = rawBench['unit']?.toString();
    }

    // Defensively extract image URLs
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

    final rawHumanPoison = json['poisonous_to_humans'];
    final rawPetPoison = json['poisonous_to_pets'];

    return PerenualDetailModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      commonName: (json['common_name'] as String?)?.trim() ?? '',
      scientificName: sciNames,
      otherName: otherNames,
      family: json['family'] as String?,
      origin: originList,
      soil: soilList,
      type: json['type'] as String?,
      dimension: json['dimension'] as String?,
      cycle: json['cycle'] as String?,
      watering: json['watering'] as String?,
      wateringGeneralBenchmarkValue: benchVal,
      wateringGeneralBenchmarkUnit: benchUnit,
      sunlight: sunlightList,
      careLevel: json['care_level'] as String?,
      maintenance: json['maintenance'] as String?,
      growthRate: json['growth_rate'] as String?,
      poisonousToHumans: rawHumanPoison == 1 || rawHumanPoison == true,
      poisonousToPets: rawPetPoison == 1 || rawPetPoison == true,
      description: json['description'] as String?,
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
        'origin': origin,
        'soil': soil,
        'type': type,
        'dimension': dimension,
        'cycle': cycle,
        'watering': watering,
        'watering_general_benchmark': wateringGeneralBenchmarkValue != null
            ? {
                'value': wateringGeneralBenchmarkValue,
                'unit': wateringGeneralBenchmarkUnit,
              }
            : null,
        'sunlight': sunlight,
        'care_level': careLevel,
        'maintenance': maintenance,
        'growth_rate': growthRate,
        'poisonous_to_humans': poisonousToHumans ? 1 : 0,
        'poisonous_to_pets': poisonousToPets ? 1 : 0,
        'description': description,
        'default_image': defaultImageUrl != null
            ? {
                'regular_url': defaultImageUrl,
                'thumbnail': defaultImageThumbnail,
              }
            : null,
      };

  /// Computes default watering interval in days.
  int get wateringIntervalDays {
    if (wateringGeneralBenchmarkValue != null) {
      final numbers = RegExp(r'\d+')
          .allMatches(wateringGeneralBenchmarkValue!)
          .map((m) => int.tryParse(m.group(0) ?? ''))
          .whereType<int>()
          .toList();
      if (numbers.isNotEmpty) {
        final avg = (numbers.reduce((a, b) => a + b) / numbers.length).round();
        if (avg > 0) return avg;
      }
    }

    final w = (watering ?? '').toLowerCase();
    if (w.contains('frequent')) return 3;
    if (w.contains('average')) return 7;
    if (w.contains('minimum')) return 14;
    if (w.contains('none')) return 21;
    return 7;
  }

  /// Formats toxicity description.
  String get toxicityDescription {
    if (poisonousToPets && poisonousToHumans) {
      return 'Beracun untuk manusia & hewan peliharaan';
    }
    if (poisonousToPets) {
      return 'Beracun untuk hewan peliharaan (anjing/kucing)';
    }
    if (poisonousToHumans) {
      return 'Beracun bila tertelan manusia';
    }
    return 'Aman (Non-toxic)';
  }

  /// Maps care level to standard application levels.
  String get careLevelDisplay {
    final level = (careLevel ?? maintenance ?? '').trim().toUpperCase();
    if (level.contains('LOW') || level.contains('NONE') || level.contains('EASY')) {
      return 'EASY CARE';
    }
    if (level.contains('HIGH') || level.contains('HARD')) {
      return 'EXPERT';
    }
    if (level.contains('MEDIUM') || level.contains('MODERATE')) {
      return 'INTERMEDIATE';
    }
    return 'EASY CARE';
  }

  /// Maps Perenual sunlight strings to readable display.
  String get sunlightDisplay {
    if (sunlight.isEmpty) return 'Sinar Tidak Langsung Sedang';
    return sunlight.join(', ');
  }

  /// Maps this Perenual Detail DTO directly into the SQLite `plant_catalog` model.
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
      cachedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerenualDetailModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PerenualDetailModel(id: $id, commonName: $commonName, scientificName: $scientificName)';
}
