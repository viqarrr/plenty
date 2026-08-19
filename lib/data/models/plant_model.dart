import 'package:flutter/foundation.dart';

/// Data Model representing an adopted user plant with its level, XP, and growth configuration.
@immutable
class PlantModel {
  final String id;
  final String userId;
  final String? catalogId;
  final String nickname;
  final bool isIndoor;
  final String? sunlightCondition;
  final String? potSize;
  final String? windowDistance;
  final double? initialHeightCm;
  final DateTime adoptedAt;
  final String? coverPhotoPath;
  final String healthStatus;
  final int level;
  final int xp;
  final bool isArchived;
  final String? commonName;
  final int defaultWateringInterval;

  // Additional descriptive fields (with sensible defaults)
  final String _specificArea;
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
    this.catalogId,
    String? nickname,
    String? name,
    bool? isIndoor,
    String? location,
    String? sunlightCondition,
    String? lightIntensity,
    String? lightSchedule,
    String? potSize,
    String? containerDetail,
    String? windowDistance,
    String? distanceFromWindow,
    this.initialHeightCm,
    DateTime? adoptedAt,
    String? coverPhotoPath,
    String? imageAsset,
    this.healthStatus = 'healthy',
    this.level = 1,
    this.xp = 0,
    this.isArchived = false,
    String? commonName,
    String? scientificName,
    this.defaultWateringInterval = 3,
    String? specificArea,
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
  }) : id = id ?? 'plt_${DateTime.now().millisecondsSinceEpoch}',
       userId = userId ?? 'usr_default',
       nickname = nickname ?? name ?? 'Tanaman Hias',
       isIndoor =
           isIndoor ??
           (location != null ? location.toLowerCase() == 'indoor' : true),
       sunlightCondition = sunlightCondition ?? lightIntensity ?? lightSchedule,
       potSize = potSize ?? containerDetail,
       windowDistance = windowDistance ?? distanceFromWindow,
       adoptedAt = adoptedAt ?? DateTime.now(),
       coverPhotoPath = coverPhotoPath ?? imageAsset,
       commonName = commonName ?? scientificName,
       _specificArea =
           specificArea ?? ((isIndoor ?? true) ? 'Ruang Tamu' : 'Balkon'),
       _careLevel = careLevel ?? 'EASY CARE',
       _waterSchedule = waterSchedule ?? 'Setiap $defaultWateringInterval Hari',
       _toxicity = toxicity ?? '',
       _description =
           description ?? 'Tanaman hias favorit dengan perawatan teratur.',
       _maxHeight = maxHeight ?? '${(initialHeightCm ?? 30.0).toInt()} cm',
       _growthRate = growthRate ?? 'Sedang',
       _growthCycle = growthCycle ?? 'Perenial',
       _pruningSeason = pruningSeason ?? 'Musim Semi',
       _flowerStatus = flowerStatus ?? 'Jarang Berbunga',
       _pests = pests ?? 'Kutu putih, tungau',
       _isCustom = isCustom ?? (catalogId == null),
       _hasTimeCapsule = hasTimeCapsule ?? false,
       _timeCapsuleMessage = timeCapsuleMessage ?? '',
       _nextWaterDate =
           nextWaterDate ?? 'Siram dalam $defaultWateringInterval hari',
       _lastCleanedDate = lastCleanedDate ?? 'Kemarin';

  factory PlantModel.fromMap(Map<String, dynamic> map) => PlantModel(
    id: map['id'] as String?,
    userId: map['user_id']?.toString() ?? '1',
    catalogId: map['catalog_id'] as String?,
    nickname: map['nickname'] as String?,
    isIndoor: (map['is_indoor'] as int? ?? 1) == 1,
    sunlightCondition: map['sunlight_condition'] as String?,
    potSize: map['pot_size'] as String?,
    windowDistance: map['window_distance'] as String?,
    initialHeightCm: (map['initial_height_cm'] as num?)?.toDouble(),
    adoptedAt: map['adopted_at'] != null
        ? DateTime.tryParse(map['adopted_at'] as String)
        : null,
    coverPhotoPath: map['cover_photo_path'] as String?,
    healthStatus: map['health_status'] as String? ?? 'healthy',
    level: map['level'] as int? ?? 1,
    xp: map['xp'] as int? ?? 0,
    isArchived: (map['is_archived'] as int? ?? 0) == 1,
    commonName: map['common_name'] as String?,
    defaultWateringInterval: map['default_watering_interval'] as int? ?? 3,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': int.tryParse(userId) ?? 1,
    'catalog_id': catalogId,
    'nickname': nickname,
    'is_indoor': isIndoor ? 1 : 0,
    'sunlight_condition': sunlightCondition,
    'pot_size': potSize,
    'window_distance': windowDistance,
    'initial_height_cm': initialHeightCm,
    'adopted_at': adoptedAt.toIso8601String(),
    'cover_photo_path': coverPhotoPath,
    'health_status': healthStatus,
    'level': level,
    'xp': xp,
    'is_archived': isArchived ? 1 : 0,
  };

  factory PlantModel.fromJson(Map<String, dynamic> json) =>
      PlantModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  // Helper getters for presentation layer convenience
  String get name => nickname;
  String get scientificName => commonName ?? 'Tanaman Hias';
  String get location => isIndoor ? 'Indoor' : 'Outdoor';
  String get containerDetail => potSize ?? 'Pot Standar';
  String get lightIntensity => sunlightCondition ?? 'Sinar Tidak Langsung';
  String get distanceFromWindow =>
      windowDistance ?? 'Dekat Jendela (1-1.5 meter)';
  String get specificArea => _specificArea;
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

  PlantModel copyWith({
    String? id,
    String? userId,
    String? catalogId,
    String? nickname,
    String? name,
    bool? isIndoor,
    String? location,
    String? sunlightCondition,
    String? lightIntensity,
    String? lightSchedule,
    String? potSize,
    String? containerDetail,
    String? windowDistance,
    String? distanceFromWindow,
    double? initialHeightCm,
    DateTime? adoptedAt,
    String? coverPhotoPath,
    String? imageAsset,
    String? healthStatus,
    int? level,
    int? xp,
    bool? isArchived,
    String? commonName,
    String? scientificName,
    int? defaultWateringInterval,
    String? specificArea,
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
  }) {
    return PlantModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      catalogId: catalogId ?? this.catalogId,
      nickname: nickname ?? name ?? this.nickname,
      isIndoor: isIndoor ?? this.isIndoor,
      sunlightCondition: sunlightCondition ?? this.sunlightCondition,
      potSize: potSize ?? this.potSize,
      windowDistance: windowDistance ?? this.windowDistance,
      initialHeightCm: initialHeightCm ?? this.initialHeightCm,
      adoptedAt: adoptedAt ?? this.adoptedAt,
      coverPhotoPath: coverPhotoPath ?? this.coverPhotoPath,
      healthStatus: healthStatus ?? this.healthStatus,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      isArchived: isArchived ?? this.isArchived,
      commonName: commonName ?? scientificName ?? this.commonName,
      defaultWateringInterval:
          defaultWateringInterval ?? this.defaultWateringInterval,
      specificArea: specificArea ?? _specificArea,
      careLevel: careLevel ?? _careLevel,
      waterSchedule: waterSchedule ?? _waterSchedule,
      toxicity: toxicity ?? _toxicity,
      description: description ?? _description,
      maxHeight: maxHeight ?? _maxHeight,
      growthRate: growthRate ?? _growthRate,
      growthCycle: growthCycle ?? _growthCycle,
      pruningSeason: pruningSeason ?? _pruningSeason,
      flowerStatus: flowerStatus ?? _flowerStatus,
      pests: pests ?? _pests,
      isCustom: isCustom ?? _isCustom,
      hasTimeCapsule: hasTimeCapsule ?? _hasTimeCapsule,
      timeCapsuleMessage: timeCapsuleMessage ?? _timeCapsuleMessage,
      nextWaterDate: nextWaterDate ?? _nextWaterDate,
      lastCleanedDate: lastCleanedDate ?? _lastCleanedDate,
    );
  }

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
