import 'package:flutter/foundation.dart';

/// Immutable model representing user onboarding care preferences.
@immutable
class UserPreference {
  final String experienceLevel;
  final double dailyTimeMinutes;
  final bool hasPets;
  final bool hasKids;

  const UserPreference({
    this.experienceLevel = '',
    this.dailyTimeMinutes = 15.0,
    this.hasPets = false,
    this.hasKids = false,
  });

  UserPreference copyWith({
    String? experienceLevel,
    double? dailyTimeMinutes,
    bool? hasPets,
    bool? hasKids,
  }) {
    return UserPreference(
      experienceLevel: experienceLevel ?? this.experienceLevel,
      dailyTimeMinutes: dailyTimeMinutes ?? this.dailyTimeMinutes,
      hasPets: hasPets ?? this.hasPets,
      hasKids: hasKids ?? this.hasKids,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreference &&
          runtimeType == other.runtimeType &&
          experienceLevel == other.experienceLevel &&
          dailyTimeMinutes == other.dailyTimeMinutes &&
          hasPets == other.hasPets &&
          hasKids == other.hasKids;

  @override
  int get hashCode =>
      experienceLevel.hashCode ^
      dailyTimeMinutes.hashCode ^
      hasPets.hashCode ^
      hasKids.hashCode;
}
