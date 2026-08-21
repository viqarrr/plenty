import 'package:flutter/material.dart';

/// Entity model representing a custom plant location (site / room)
/// saved by the user in the SQLite database.
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

  static final Map<int, IconData> _iconMap = {
    Icons.weekend_outlined.codePoint: Icons.weekend_outlined,
    Icons.bed_outlined.codePoint: Icons.bed_outlined,
    Icons.soup_kitchen_outlined.codePoint: Icons.soup_kitchen_outlined,
    Icons.computer_outlined.codePoint: Icons.computer_outlined,
    Icons.table_restaurant_outlined.codePoint: Icons.table_restaurant_outlined,
    Icons.chair_outlined.codePoint: Icons.chair_outlined,
    Icons.bathtub_outlined.codePoint: Icons.bathtub_outlined,
    Icons.meeting_room_outlined.codePoint: Icons.meeting_room_outlined,
    Icons.balcony_outlined.codePoint: Icons.balcony_outlined,
    Icons.yard_outlined.codePoint: Icons.yard_outlined,
    Icons.deck_outlined.codePoint: Icons.deck_outlined,
    Icons.fence_outlined.codePoint: Icons.fence_outlined,
    Icons.window_outlined.codePoint: Icons.window_outlined,
    Icons.roofing_outlined.codePoint: Icons.roofing_outlined,
    Icons.park_outlined.codePoint: Icons.park_outlined,
    Icons.local_florist_outlined.codePoint: Icons.local_florist_outlined,
  };

  IconData get iconData => _iconMap[iconCode] ?? Icons.meeting_room_outlined;

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
      iconCode: (map['icon_code'] as num?)?.toInt() ??
          Icons.meeting_room_outlined.codePoint,
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
}
