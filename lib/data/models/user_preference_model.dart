import 'package:flutter/foundation.dart';
import 'package:plenty/data/datasources/preference_handler.dart';

/// Consolidated Data Model representing user onboarding care preferences.
@immutable
class UserPreferenceModel {
  final String id;
  final String userId;
  final String experienceLevel;
  final double dailyTimeMinutes;
  final bool hasPets;
  final bool hasKids;
  final bool hasCompletedOnboarding;

  const UserPreferenceModel({
    this.id = '',
    this.userId = '',
    this.experienceLevel = 'beginner',
    this.dailyTimeMinutes = 15.0,
    this.hasPets = false,
    this.hasKids = false,
    this.hasCompletedOnboarding = false,
  });

  /// Factory to initialize a new preference model with the active user's ID from PreferenceHandler
  static Future<UserPreferenceModel> createWithActiveUser({
    String? id,
    String experienceLevel = 'beginner',
    double dailyTimeMinutes = 15.0,
    bool hasPets = false,
    bool hasKids = false,
    bool hasCompletedOnboarding = false,
  }) async {
    final activeUser = await PreferenceHandler.getUser();
    final activeUserId = activeUser?.id.toString() ?? 'usr_default';

    return UserPreferenceModel(
      id: id ?? 'pref_${DateTime.now().millisecondsSinceEpoch}',
      userId: activeUserId,
      experienceLevel: experienceLevel,
      dailyTimeMinutes: dailyTimeMinutes,
      hasPets: hasPets,
      hasKids: hasKids,
      hasCompletedOnboarding: hasCompletedOnboarding,
    );
  }

  UserPreferenceModel copyWith({
    String? id,
    String? userId,
    String? experienceLevel,
    double? dailyTimeMinutes,
    bool? hasPets,
    bool? hasKids,
    bool? hasCompletedOnboarding,
  }) {
    return UserPreferenceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      dailyTimeMinutes: dailyTimeMinutes ?? this.dailyTimeMinutes,
      hasPets: hasPets ?? this.hasPets,
      hasKids: hasKids ?? this.hasKids,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  factory UserPreferenceModel.fromMap(Map<String, dynamic> map) {
    return UserPreferenceModel(
      id: (map['id'] as String?) ?? '',
      userId: map['user_id']?.toString() ?? '1',
      experienceLevel: (map['experience_level'] as String?) ?? 'beginner',
      dailyTimeMinutes: (map['daily_time_minutes'] as num?)?.toDouble() ?? 15.0,
      hasPets: map['has_pets'] == 1 || map['has_pets'] == true,
      hasKids: map['has_kids'] == 1 || map['has_kids'] == true,
      hasCompletedOnboarding:
          map['has_completed_onboarding'] == 1 ||
          map['has_completed_onboarding'] == true ||
          map['has_completed_onboarding'] == '1',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id.isEmpty ? 'pref_${DateTime.now().millisecondsSinceEpoch}' : id,
      'user_id': int.tryParse(userId) ?? 1,
      'experience_level': experienceLevel,
      'daily_time_minutes': dailyTimeMinutes,
      'has_pets': hasPets ? 1 : 0,
      'has_kids': hasKids ? 1 : 0,
      'has_completed_onboarding': hasCompletedOnboarding ? 1 : 0,
    };
  }

  factory UserPreferenceModel.fromJson(Map<String, dynamic> json) =>
      UserPreferenceModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferenceModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          experienceLevel == other.experienceLevel &&
          dailyTimeMinutes == other.dailyTimeMinutes &&
          hasPets == other.hasPets &&
          hasKids == other.hasKids &&
          hasCompletedOnboarding == other.hasCompletedOnboarding;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      experienceLevel.hashCode ^
      dailyTimeMinutes.hashCode ^
      hasPets.hashCode ^
      hasKids.hashCode ^
      hasCompletedOnboarding.hashCode;

  @override
  String toString() =>
      'UserPreferenceModel(id: $id, userId: $userId, experienceLevel: $experienceLevel, dailyTimeMinutes: $dailyTimeMinutes, hasPets: $hasPets, hasKids: $hasKids, hasCompletedOnboarding: $hasCompletedOnboarding)';
}
