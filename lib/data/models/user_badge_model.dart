import 'package:flutter/foundation.dart';
import 'package:plenty/data/models/badge_model.dart';

/// Data Model representing an achievement badge unlocked by a user.
@immutable
class UserBadgeModel {
  final String id;
  final String userId;
  final String badgeId;
  final DateTime unlockedAt;
  final BadgeModel? badge;

  const UserBadgeModel({
    required this.id,
    required this.userId,
    required this.badgeId,
    required this.unlockedAt,
    this.badge,
  });

  factory UserBadgeModel.fromMap(Map<String, dynamic> map, {BadgeModel? badge}) =>
      UserBadgeModel(
        id: map['id'] as String,
        userId: map['user_id']?.toString() ?? '1',
        badgeId: map['badge_id'] as String,
        unlockedAt: DateTime.parse(map['unlocked_at'] as String),
        badge: badge,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': int.tryParse(userId) ?? 1,
        'badge_id': badgeId,
        'unlocked_at': unlockedAt.toIso8601String(),
      };

  factory UserBadgeModel.fromJson(Map<String, dynamic> json) =>
      UserBadgeModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserBadgeModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'UserBadgeModel(id: $id, userId: $userId, badgeId: $badgeId, unlockedAt: $unlockedAt)';
}
