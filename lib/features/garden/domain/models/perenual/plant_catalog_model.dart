import 'package:flutter/foundation.dart';
import 'package:plenty/core/utils/botanical_translator.dart';
import 'package:plenty/core/utils/botanical_unit_converter.dart';

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
  final String? toxicity;
  final bool? isToxicToPets;
  final String? dimension;
  final String? growthRate;
  final String? cycle;
  final String? pruningMonth;
  final String? floweringSeason;
  final String? description;
  final String? origin;
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
    this.toxicity,
    this.isToxicToPets,
    this.dimension,
    this.growthRate,
    this.cycle,
    this.pruningMonth,
    this.floweringSeason,
    this.description,
    this.origin,
    required this.cachedAt,
  });

  /// Evaluates whether the plant is toxic to pets or humans
  bool get isToxic {
    if (isToxicToPets != null) return isToxicToPets!;
    if (toxicity != null && toxicity!.isNotEmpty) {
      final t = toxicity!.toLowerCase();
      return t.contains('beracun') ||
          t.contains('toxic') ||
          t.contains('bahaya') ||
          t.contains('poisonous');
    }

    final name = commonName.toLowerCase();
    final sci = (scientificName ?? '').toLowerCase();
    final fam = (family ?? '').toLowerCase();

    if (name.contains('monstera') ||
        name.contains('pothos') ||
        name.contains('sansevieria') ||
        name.contains('snake') ||
        name.contains('peace lily') ||
        name.contains('zz plant') ||
        sci.contains('epipremnum') ||
        sci.contains('dieffenbachia') ||
        sci.contains('philodendron') ||
        fam.contains('araceae')) {
      return true;
    }
    return false;
  }

  /// User-facing toxicity description label
  String get toxicityLabel =>
      isToxic ? 'Beracun bagi hewan' : 'Aman untuk hewan';

  /// Detailed toxicity description for preview screen
  String get toxicityDescription => isToxic
      ? (toxicity ??
            'Beracun jika tertelan oleh anjing atau kucing. Jauhkan dari jangkauan hewan peliharaan.')
      : (toxicity ??
            'Tanaman ini ramah hewan peliharaan (Pet-friendly) dan aman di rumah.');

  /// Formatted metric dimension
  String get dimensionDisplay =>
      BotanicalUnitConverter.convertToMetric(dimension);

  /// Localized growth rate
  String get growthRateDisplay =>
      BotanicalTranslator.translateGrowthRate(growthRate);

  /// Localized cycle
  String get cycleDisplay => BotanicalTranslator.translateCycle(cycle);

  /// Localized pruning season
  String get pruningDisplay =>
      BotanicalTranslator.translatePruningMonth(pruningMonth);

  /// Localized flowering season
  String get floweringDisplay => BotanicalTranslator.translateFloweringSeason(
    floweringSeason,
    commonName: commonName,
  );

  /// Full botanical overview in Indonesian
  String get overviewDisplay =>
      BotanicalTranslator.translateOrGenerateDescription(
        rawDescription: description,
        commonName: commonName,
        scientificName: scientificName,
        family: family,
        careLevel: careLevel,
        defaultWateringInterval: defaultWateringInterval,
      );

  PlantCatalogModel copyWith({
    String? id,
    String? commonName,
    String? scientificName,
    String? family,
    int? defaultWateringInterval,
    String? sunlightLevel,
    String? careLevel,
    String? imageUrl,
    String? localImagePath,
    String? toxicity,
    bool? isToxicToPets,
    String? dimension,
    String? growthRate,
    String? cycle,
    String? pruningMonth,
    String? floweringSeason,
    String? description,
    String? origin,
    DateTime? cachedAt,
  }) {
    return PlantCatalogModel(
      id: id ?? this.id,
      commonName: commonName ?? this.commonName,
      scientificName: scientificName ?? this.scientificName,
      family: family ?? this.family,
      defaultWateringInterval:
          defaultWateringInterval ?? this.defaultWateringInterval,
      sunlightLevel: sunlightLevel ?? this.sunlightLevel,
      careLevel: careLevel ?? this.careLevel,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      toxicity: toxicity ?? this.toxicity,
      isToxicToPets: isToxicToPets ?? this.isToxicToPets,
      dimension: dimension ?? this.dimension,
      growthRate: growthRate ?? this.growthRate,
      cycle: cycle ?? this.cycle,
      pruningMonth: pruningMonth ?? this.pruningMonth,
      floweringSeason: floweringSeason ?? this.floweringSeason,
      description: description ?? this.description,
      origin: origin ?? this.origin,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  factory PlantCatalogModel.fromMap(Map<String, dynamic> map) {
    return PlantCatalogModel(
      id: map['id'] as String,
      commonName: map['common_name'] as String,
      scientificName: map['scientific_name'] as String?,
      family: map['family'] as String?,
      defaultWateringInterval: map['default_watering_interval'] as int? ?? 3,
      sunlightLevel: map['sunlight_level'] as String?,
      careLevel: map['care_level'] as String?,
      imageUrl: map['image_url'] as String?,
      localImagePath: map['local_image_path'] as String?,
      toxicity: map['toxicity'] as String?,
      isToxicToPets: map['is_toxic'] != null
          ? (map['is_toxic'] == 1 || map['is_toxic'] == true)
          : null,
      dimension: map['dimension'] as String?,
      growthRate: map['growth_rate'] as String?,
      cycle: map['cycle'] as String?,
      pruningMonth: map['pruning_month'] as String?,
      floweringSeason: map['flowering_season'] as String?,
      description: map['description'] as String?,
      origin: map['origin'] as String?,
      cachedAt: map['cached_at'] != null
          ? (DateTime.tryParse(map['cached_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

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
    'toxicity': toxicity,
    'is_toxic': isToxic ? 1 : 0,
    'dimension': dimension,
    'growth_rate': growthRate,
    'cycle': cycle,
    'pruning_month': pruningMonth,
    'flowering_season': floweringSeason,
    'description': description,
    'origin': origin,
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
