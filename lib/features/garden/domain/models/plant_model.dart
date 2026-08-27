import 'package:flutter/foundation.dart';
import 'package:plenty/core/constants/site_icons.dart';

/// Data Model representing an adopted user plant with its level, XP, and growth configuration.
@immutable
class PlantModel {
  final String id;
  final String userId;
  final int? speciesId;
  final String? catalogId;
  final String nickname;
  final bool isIndoor;
  final String? sunlightCondition;
  final String? potSize;
  final String siteId;
  final double? initialHeightCm;
  final String growthStage;
  final DateTime adoptedAt;
  final String? coverPhotoPath;
  final String healthStatus;
  final int level;
  final int xp;
  final bool isArchived;
  final String? commonName;
  final String? _scientificName;
  final int defaultWateringInterval;
  final bool isPetFriendly;

  // Additional descriptive fields (with sensible defaults)
  final String _careLevel;
  final String _waterSchedule;
  final String _toxicity;
  final String _description;
  final String _maxHeight;
  final String _growthRate;
  final String _growthCycle;
  final String _pruningSeason;
  final String _flowerStatus;
  final String _pests;
  final bool _isCustom;
  final bool _hasTimeCapsule;
  final String _timeCapsuleMessage;
  final String _nextWaterDate;
  final String _lastCleanedDate;

  PlantModel({
    String? id,
    String? userId,
    this.speciesId,
    this.catalogId,
    String? nickname,
    String? name,
    bool? isIndoor,
    String? placementType,
    String? sunlightCondition,
    String? sunlightPreference,
    String? lightIntensity,
    String? lightSchedule,
    String? potSize,
    String? containerDetail,
    String? siteId,
    double? initialHeightCm,
    double? initialHeight,
    double? currentHeight,
    this.growthStage = 'mature',
    DateTime? adoptedAt,
    String? coverPhotoPath,
    String? imagePath,
    String? imageAsset,
    this.healthStatus = 'healthy',
    this.level = 1,
    this.xp = 0,
    this.isArchived = false,
    String? commonName,
    String? speciesName,
    String? scientificName,
    int? defaultWateringInterval,
    int? wateringIntervalDays,
    bool? isPetFriendly,
    bool? isToxic,
    String? careLevel,
    String? waterSchedule,
    String? toxicity,
    String? description,
    String? maxHeight,
    String? growthRate,
    String? growthCycle,
    String? pruningSeason,
    String? flowerStatus,
    String? pests,
    bool? isCustom,
    bool? hasTimeCapsule,
    String? timeCapsuleMessage,
    String? nextWaterDate,
    String? lastCleanedDate,
  })  : id = id ?? 'plt_${DateTime.now().millisecondsSinceEpoch}',
        userId = userId ?? 'usr_default',
        nickname = nickname ?? name ?? 'Tanaman Hias',
        isIndoor = isIndoor ??
            (placementType != null
                ? placementType.toLowerCase() == 'indoor'
                : true),
        sunlightCondition = sunlightCondition ??
            sunlightPreference ??
            lightIntensity ??
            lightSchedule,
        potSize = potSize ?? containerDetail,
        siteId = siteId ?? SiteIcons.defaultLivingRoomId,
        initialHeightCm = initialHeightCm ?? initialHeight,
        adoptedAt = adoptedAt ?? DateTime.now(),
        coverPhotoPath = coverPhotoPath ?? imagePath ?? imageAsset,
        commonName = commonName ?? speciesName ?? scientificName,
        _scientificName = scientificName,
        defaultWateringInterval =
            defaultWateringInterval ?? wateringIntervalDays ?? 7,
        isPetFriendly = isPetFriendly ??
            (isToxic != null
                ? !isToxic
                : (toxicity != null
                    ? !toxicity.toLowerCase().contains('beracun')
                    : true)),
        _careLevel = careLevel ?? 'EASY CARE',
        _waterSchedule = waterSchedule ??
            'Setiap ${defaultWateringInterval ?? wateringIntervalDays ?? 7} Hari',
        _toxicity = toxicity ?? '',
        _description =
            description ?? 'Tanaman hias favorit dengan perawatan teratur.',
        _maxHeight = maxHeight ??
            '${(initialHeightCm ?? initialHeight ?? 30.0).toInt()} cm',
        _growthRate = growthRate ?? 'Sedang',
        _growthCycle = growthCycle ?? 'Perenial',
        _pruningSeason = pruningSeason ?? 'Musim Semi',
        _flowerStatus = flowerStatus ?? 'Jarang Berbunga',
        _pests = pests ?? 'Kutu putih, tungau',
        _isCustom = isCustom ?? (catalogId == null && speciesId == null),
        _hasTimeCapsule = hasTimeCapsule ?? false,
        _timeCapsuleMessage = timeCapsuleMessage ?? '',
        _nextWaterDate = nextWaterDate ??
            'Siram dalam ${defaultWateringInterval ?? wateringIntervalDays ?? 7} hari',
        _lastCleanedDate = lastCleanedDate ?? 'Kemarin';

  factory PlantModel.fromMap(Map<String, dynamic> map) {
    final rawSiteId = (map['site_id'] ?? map['site'] ?? map['room_name']) as String?;
    final commonNameVal =
        (map['species_name'] ?? map['common_name']) as String?;
    final isIndoorVal = map['placement_type'] != null
        ? (map['placement_type'] == 'Indoor')
        : ((map['is_indoor'] as int? ?? 1) == 1);
    final rawHeight = (map['initial_height_cm'] ??
        map['current_height'] ??
        map['initial_height']) as num?;
    final initialH = (map['initial_height_cm'] as num?)?.toDouble() ??
        (map['current_height'] as num?)?.toDouble() ??
        (map['initial_height'] as num?)?.toDouble() ??
        (rawHeight?.toDouble() ?? 30.0);
    final photo = (map['image_path'] ?? map['cover_photo_path']) as String?;
    final interval = (map['watering_interval_days'] ??
        map['default_watering_interval']) as int? ??
        7;
    final petFriendly = (map['is_pet_friendly'] as int? ??
            (map['is_toxic'] != null && map['is_toxic'] == 0 ? 1 : 0)) ==
        1;

    DateTime? parseAdoptedAt(dynamic val) {
      if (val == null) return null;
      if (val is int) {
        return val > 1000000000000
            ? DateTime.fromMillisecondsSinceEpoch(val)
            : DateTime.fromMillisecondsSinceEpoch(val * 1000);
      }
      return DateTime.tryParse(val.toString());
    }

    return PlantModel(
      id: map['id'] as String?,
      userId: map['user_id']?.toString() ?? '1',
      speciesId: (map['species_id'] as num?)?.toInt(),
      catalogId: map['catalog_id'] as String?,
      nickname: (map['nickname'] ?? map['name']) as String?,
      isIndoor: isIndoorVal,
      placementType: isIndoorVal ? 'Indoor' : 'Outdoor',
      sunlightCondition:
          (map['sunlight_preference'] ?? map['sunlight_condition']) as String?,
      sunlightPreference:
          (map['sunlight_preference'] ?? map['sunlight_condition']) as String?,
      potSize: map['pot_size'] as String?,
      siteId: rawSiteId ?? SiteIcons.defaultLivingRoomId,
      initialHeightCm: initialH,
      initialHeight: initialH,
      currentHeight: rawHeight?.toDouble(),
      growthStage: map['growth_stage'] as String? ?? 'mature',
      adoptedAt: parseAdoptedAt(map['adopted_at']),
      coverPhotoPath: photo,
      imagePath: photo,
      healthStatus: map['health_status'] as String? ?? 'healthy',
      level: map['level'] as int? ?? 1,
      xp: map['xp'] as int? ?? 0,
      isArchived: (map['is_archived'] as int? ?? 0) == 1,
      commonName: commonNameVal,
      speciesName: commonNameVal,
      scientificName: map['scientific_name'] as String?,
      defaultWateringInterval: interval,
      wateringIntervalDays: interval,
      isPetFriendly: petFriendly,
      careLevel: map['care_level'] as String?,
      toxicity: map['toxicity'] as String?,
      description: map['description'] as String?,
      growthRate: map['growth_rate'] as String?,
      growthCycle: map['growth_cycle'] as String?,
      pruningSeason: map['pruning_season'] as String?,
      flowerStatus: map['flower_status'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'catalog_id': catalogId,
        'species_id': speciesId,
        'species_name': commonName ?? nickname,
        'scientific_name': scientificName,
        'nickname': nickname,
        'placement_type': isIndoor ? 'Indoor' : 'Outdoor',
        'site_id': siteId,
        'pot_size': potSize,
        'initial_height': initialHeightCm ?? 30.0,
        'current_height': currentHeightCm,
        'image_path': coverPhotoPath,
        'watering_interval_days': defaultWateringInterval,
        'sunlight_preference': sunlightCondition,
        'is_pet_friendly': isPetFriendly ? 1 : 0,
        'adopted_at': adoptedAt.toIso8601String(),
        'is_indoor': isIndoor ? 1 : 0,
        'sunlight_condition': sunlightCondition,
        'initial_height_cm': initialHeightCm ?? 30.0,
        'growth_stage': growthStage,
        'cover_photo_path': coverPhotoPath,
        'health_status': healthStatus,
        'level': level,
        'xp': xp,
        'is_archived': isArchived ? 1 : 0,
        'default_watering_interval': defaultWateringInterval,
        'care_level': careLevel,
        'toxicity': toxicity,
        'description': description,
        'growth_rate': growthRate,
        'growth_cycle': growthCycle,
        'pruning_season': pruningSeason,
        'flower_status': flowerStatus,
      };

  factory PlantModel.fromJson(Map<String, dynamic> json) =>
      PlantModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  // Helper getters for presentation layer convenience
  String get name => nickname;
  String get scientificName => _scientificName ?? commonName ?? 'Tanaman Hias';
  String get containerDetail => potSize ?? 'Pot Standar';
  String get lightIntensity => sunlightCondition ?? 'Sinar Tidak Langsung';
  String get imageAsset => coverPhotoPath ?? 'assets/images/custom_plant.png';
  String? get imageUrl => coverPhotoPath;
  String get careLevel => _careLevel;
  String get waterSchedule => _waterSchedule;
  String get lightSchedule => sunlightCondition ?? 'Sinar Tidak Langsung';
  String get toxicity => _toxicity;
  String get description => _description;
  String get maxHeight => _maxHeight;
  String get growthRate => _growthRate;
  String get growthCycle => _growthCycle;
  String get pruningSeason => _pruningSeason;
  String get flowerStatus => _flowerStatus;
  String get pests => _pests;
  bool get isCustom => _isCustom;
  bool get hasTimeCapsule => _hasTimeCapsule;
  String get timeCapsuleMessage => _timeCapsuleMessage;
  String get nextWaterDate => _nextWaterDate;
  String get lastCleanedDate => _lastCleanedDate;
  double get currentHeightCm => initialHeightCm ?? 30.0;
  String get wateringSchedule => defaultWateringInterval.toString();
  String get temperatureRange => '18-28°C';
  bool get isFromSeed => growthStage == 'seed';
  String get growthStageLabel => isFromSeed ? 'Dari Bibit' : 'Sudah Tumbuh';

  /// Formatted plant age string derived from [adoptedAt] (e.g., '1 Hari', '24 Hari', '3 Bulan', '1 Thn 2 Bln').
  String get ageDisplay {
    final now = DateTime.now();
    final startDate = DateTime(adoptedAt.year, adoptedAt.month, adoptedAt.day);
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(startDate).inDays;

    if (days <= 0) {
      return '1 Hari';
    } else if (days < 30) {
      return '$days Hari';
    } else if (days < 365) {
      final months = days ~/ 30;
      final remainingDays = days % 30;
      if (remainingDays > 0) {
        return '$months Bln $remainingDays Hr';
      }
      return '$months Bulan';
    } else {
      final years = days ~/ 365;
      final remainingMonths = (days % 365) ~/ 30;
      if (remainingMonths > 0) {
        return '$years Thn $remainingMonths Bln';
      }
      return '$years Tahun';
    }
  }

  PlantModel copyWith({
    String? id,
    String? userId,
    int? speciesId,
    String? catalogId,
    String? nickname,
    String? name,
    bool? isIndoor,
    String? placementType,
    String? sunlightCondition,
    String? sunlightPreference,
    String? lightIntensity,
    String? lightSchedule,
    String? potSize,
    String? containerDetail,
    String? siteId,
    double? initialHeightCm,
    double? initialHeight,
    double? currentHeight,
    String? growthStage,
    DateTime? adoptedAt,
    String? coverPhotoPath,
    String? imagePath,
    String? imageAsset,
    String? healthStatus,
    int? level,
    int? xp,
    bool? isArchived,
    String? commonName,
    String? speciesName,
    String? scientificName,
    int? defaultWateringInterval,
    int? wateringIntervalDays,
    bool? isPetFriendly,
    bool? isToxic,
    String? careLevel,
    String? waterSchedule,
    String? toxicity,
    String? description,
    String? maxHeight,
    String? growthRate,
    String? growthCycle,
    String? pruningSeason,
    String? flowerStatus,
    String? pests,
    bool? isCustom,
    bool? hasTimeCapsule,
    String? timeCapsuleMessage,
    String? nextWaterDate,
    String? lastCleanedDate,
  }) =>
      PlantModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        speciesId: speciesId ?? this.speciesId,
        catalogId: catalogId ?? this.catalogId,
        nickname: nickname ?? this.nickname,
        isIndoor: isIndoor ?? this.isIndoor,
        placementType: placementType ??
            (isIndoor != null ? (isIndoor ? 'Indoor' : 'Outdoor') : null),
        sunlightCondition: sunlightCondition ?? this.sunlightCondition,
        sunlightPreference: sunlightPreference ?? this.sunlightCondition,
        potSize: potSize ?? this.potSize,
        siteId: siteId ?? this.siteId,
        initialHeightCm:
            initialHeightCm ?? initialHeight ?? this.initialHeightCm,
        initialHeight: initialHeight ?? initialHeightCm ?? this.initialHeightCm,
        currentHeight: currentHeight ?? currentHeightCm,
        growthStage: growthStage ?? this.growthStage,
        adoptedAt: adoptedAt ?? this.adoptedAt,
        coverPhotoPath: coverPhotoPath ?? imagePath ?? this.coverPhotoPath,
        imagePath: imagePath ?? coverPhotoPath ?? this.coverPhotoPath,
        healthStatus: healthStatus ?? this.healthStatus,
        level: level ?? this.level,
        xp: xp ?? this.xp,
        isArchived: isArchived ?? this.isArchived,
        commonName: commonName ?? speciesName ?? this.commonName,
        speciesName: speciesName ?? commonName ?? this.commonName,
        scientificName: scientificName ?? this.scientificName,
        defaultWateringInterval: defaultWateringInterval ??
            wateringIntervalDays ??
            this.defaultWateringInterval,
        wateringIntervalDays: wateringIntervalDays ??
            defaultWateringInterval ??
            this.defaultWateringInterval,
        isPetFriendly:
            isPetFriendly ?? (isToxic != null ? !isToxic : this.isPetFriendly),
        careLevel: careLevel ?? this.careLevel,
        waterSchedule: waterSchedule ?? this.waterSchedule,
        toxicity: toxicity ?? this.toxicity,
        description: description ?? this.description,
        maxHeight: maxHeight ?? this.maxHeight,
        growthRate: growthRate ?? this.growthRate,
        growthCycle: growthCycle ?? this.growthCycle,
        pruningSeason: pruningSeason ?? this.pruningSeason,
        flowerStatus: flowerStatus ?? this.flowerStatus,
        pests: pests ?? this.pests,
        isCustom: isCustom ?? this.isCustom,
        hasTimeCapsule: hasTimeCapsule ?? this.hasTimeCapsule,
        timeCapsuleMessage: timeCapsuleMessage ?? this.timeCapsuleMessage,
        nextWaterDate: nextWaterDate ?? this.nextWaterDate,
        lastCleanedDate: lastCleanedDate ?? this.lastCleanedDate,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlantModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PlantModel(id: $id, nickname: $nickname, level: $level, xp: $xp)';
}
