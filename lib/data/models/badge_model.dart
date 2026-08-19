import 'package:flutter/foundation.dart';

/// Data Model representing an unlockable achievement/badge.
@immutable
class BadgeModel {
  final String id;
  final String title;
  final String description;
  final String iconAssetPath;

  const BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconAssetPath,
  });

  factory BadgeModel.fromMap(Map<String, dynamic> map) => BadgeModel(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        iconAssetPath: map['icon_asset_path'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'icon_asset_path': iconAssetPath,
      };

  factory BadgeModel.fromJson(Map<String, dynamic> json) =>
      BadgeModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BadgeModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BadgeModel(id: $id, title: $title)';
}
