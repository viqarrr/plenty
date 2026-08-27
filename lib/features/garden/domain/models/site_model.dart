import 'package:flutter/foundation.dart';

/// Entity model representing a plant location (site / room)
/// saved in the SQLite database (both default and custom sites).
@immutable
class SiteModel {
  final String id;
  final String userId;
  final String name;
  final int iconCode;
  final bool isIndoor;
  final bool isCustom;
  final DateTime createdAt;

  const SiteModel({
    required this.id,
    this.userId = '1',
    required this.name,
    required this.iconCode,
    this.isIndoor = true,
    this.isCustom = true,
    required this.createdAt,
  });

  factory SiteModel.fromMap(Map<String, dynamic> map) => SiteModel(
    id: map['id'] as String,
    userId: map['user_id']?.toString() ?? '1',
    name: map['name'] as String,
    iconCode: (map['icon_code'] as num?)?.toInt() ?? 58428,
    isIndoor: (map['is_indoor'] as int? ?? 1) == 1,
    isCustom: (map['is_custom'] as int? ?? 1) == 1,
    createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
        DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': int.tryParse(userId) ?? 1,
    'name': name,
    'icon_code': iconCode,
    'is_indoor': isIndoor ? 1 : 0,
    'is_custom': isCustom ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
  };

  SiteModel copyWith({
    String? id,
    String? userId,
    String? name,
    int? iconCode,
    bool? isIndoor,
    bool? isCustom,
    DateTime? createdAt,
  }) {
    return SiteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      isIndoor: isIndoor ?? this.isIndoor,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          iconCode == other.iconCode &&
          isIndoor == other.isIndoor &&
          isCustom == other.isCustom;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      iconCode.hashCode ^
      isIndoor.hashCode ^
      isCustom.hashCode;
}
