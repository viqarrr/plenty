import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';

/// Data Model representing user streak state, tier, and freeze tokens.
@immutable
class UserStreakModel {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final int currentTier;
  final String? lastStreakDate;
  final int freezeTokensAvailable;
  final String? freezeUsedOn;

  const UserStreakModel({
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.currentTier = 1,
    this.lastStreakDate,
    this.freezeTokensAvailable = 1,
    this.freezeUsedOn,
  });

  /// Derives current tier (1-7) from streak day count.
  static int calculateTier(int streakDays) {
    if (streakDays >= 30) return 7;
    if (streakDays >= 21) return 6;
    if (streakDays >= 14) return 5;
    if (streakDays >= 7) return 4;
    if (streakDays >= 5) return 3;
    if (streakDays >= 3) return 2;
    return 1;
  }

  /// Returns corresponding tier display color.
  Color get tierColor {
    return switch (currentTier) {
      7 => AppColors.tierMythicText,
      6 => AppColors.tierLegendText,
      5 => AppColors.tierEpicText,
      4 => AppColors.tierSpecialText,
      3 => AppColors.tierEliteText,
      2 => AppColors.pastelGreenText,
      _ => AppColors.tierNormalText,
    };
  }

  /// Returns corresponding tier badge name in Indonesian.
  String get tierName {
    return switch (currentTier) {
      7 => 'Master Botanis',
      6 => 'Penjaga Hutan',
      5 => 'Pelindung Alam',
      4 => 'Tangan Hijau',
      3 => 'Penyubur Tunas',
      2 => 'Penyiram Rajin',
      _ => 'Pemula Antusias',
    };
  }

  factory UserStreakModel.fromMap(Map<String, dynamic> map) => UserStreakModel(
        userId: map['user_id']?.toString() ??
            map['id']?.toString() ??
            '1',
        currentStreak: (map['current_streak'] as int?) ??
            (map['streak_count'] as int?) ??
            0,
        longestStreak: (map['longest_streak'] as int?) ?? 0,
        currentTier: (map['current_tier'] as int?) ??
            calculateTier(
              (map['current_streak'] as int?) ??
                  (map['streak_count'] as int?) ??
                  0,
            ),
        lastStreakDate: map['last_streak_date'] as String?,
        freezeTokensAvailable:
            (map['freeze_tokens_available'] as int?) ?? 1,
        freezeUsedOn: map['freeze_used_on'] as String?,
      );

  factory UserStreakModel.fromUserMap(Map<String, dynamic> map) {
    final streak = (map['streak_count'] as int?) ?? 0;
    final longest = (map['longest_streak'] as int?) ?? streak;
    return UserStreakModel(
      userId: map['id']?.toString() ?? '1',
      currentStreak: streak,
      longestStreak: longest,
      currentTier: calculateTier(streak),
      lastStreakDate: map['last_streak_date'] as String?,
      freezeTokensAvailable: 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': int.tryParse(userId) ?? 1,
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'current_tier': currentTier,
        'last_streak_date': lastStreakDate,
        'freeze_tokens_available': freezeTokensAvailable,
        'freeze_used_on': freezeUsedOn,
      };

  factory UserStreakModel.fromJson(Map<String, dynamic> json) =>
      UserStreakModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  UserStreakModel copyWith({
    String? userId,
    int? currentStreak,
    int? longestStreak,
    int? currentTier,
    String? lastStreakDate,
    int? freezeTokensAvailable,
    String? freezeUsedOn,
  }) {
    return UserStreakModel(
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      currentTier: currentTier ?? this.currentTier,
      lastStreakDate: lastStreakDate ?? this.lastStreakDate,
      freezeTokensAvailable:
          freezeTokensAvailable ?? this.freezeTokensAvailable,
      freezeUsedOn: freezeUsedOn ?? this.freezeUsedOn,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStreakModel &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          currentStreak == other.currentStreak &&
          currentTier == other.currentTier;

  @override
  int get hashCode =>
      userId.hashCode ^ currentStreak.hashCode ^ currentTier.hashCode;

  @override
  String toString() =>
      'UserStreakModel(userId: $userId, streak: $currentStreak, tier: $currentTier)';
}
