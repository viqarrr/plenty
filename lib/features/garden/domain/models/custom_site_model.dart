import 'package:flutter/foundation.dart';

/// Entity model representing a custom plant location (site / room)
/// saved by the user in the SQLite database.
@immutable
class CustomSiteModel {
  final String id;
  final String userId;
  final String name;
  final int iconCode;
  final bool isIndoor;
  final DateTime createdAt;

  const CustomSiteModel({
    required this.id,
    this.userId = '1',
    required this.name,
    required this.iconCode,
    this.isIndoor = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': int.tryParse(userId) ?? 1,
      'name': name,
      'icon_code': iconCode,
      'is_indoor': isIndoor ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CustomSiteModel.fromMap(Map<String, dynamic> map) {
    return CustomSiteModel(
      id: map['id'] as String,
      userId: map['user_id']?.toString() ?? '1',
      name: map['name'] as String,
      iconCode: (map['icon_code'] as num?)?.toInt() ?? 58428,
      isIndoor: (map['is_indoor'] as int? ?? 1) == 1,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  CustomSiteModel copyWith({
    String? id,
    String? userId,
    String? name,
    int? iconCode,
    bool? isIndoor,
    DateTime? createdAt,
  }) {
    return CustomSiteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      isIndoor: isIndoor ?? this.isIndoor,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomSiteModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          iconCode == other.iconCode &&
          isIndoor == other.isIndoor;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ iconCode.hashCode ^ isIndoor.hashCode;
}
