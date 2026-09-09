import 'package:flutter/foundation.dart';

/// Consolidated Domain Model representing a registered User profile,
/// with progress metrics (streaks, xp, level, badges).
@immutable
class UserModel {
  final String? id;
  final String email;
  final String password;
  final String displayName;
  final String username;
  final String? bio;
  final String? avatarUrl;
  final int streakCount;
  final int longestStreak;
  final int totalXp;
  final int level;
  final int unlockedBadgesCount;
  final String? lastStreakDate;
  final String? createdAt;

  const UserModel({
    this.id,
    required this.email,
    this.password = '',
    required this.displayName,
    required this.username,
    this.bio,
    this.avatarUrl,
    this.streakCount = 0,
    this.longestStreak = 0,
    this.totalXp = 0,
    this.level = 1,
    this.unlockedBadgesCount = 0,
    this.lastStreakDate,
    this.createdAt,
  });

  /// Helper to safely retrieve an integer representation of the ID if available,
  /// or hash code fallback for legacy local SQLite tables.
  int? get numericId {
    if (id == null) return null;
    return int.tryParse(id!) ?? id.hashCode.abs();
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? password,
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
    int? streakCount,
    int? longestStreak,
    int? totalXp,
    int? level,
    int? unlockedBadgesCount,
    String? lastStreakDate,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      streakCount: streakCount ?? this.streakCount,
      longestStreak: longestStreak ?? this.longestStreak,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      unlockedBadgesCount: unlockedBadgesCount ?? this.unlockedBadgesCount,
      lastStreakDate: lastStreakDate ?? this.lastStreakDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toString(),
      email: (map['email'] as String?) ?? '',
      password: (map['password'] as String?) ?? '',
      displayName: (map['display_name'] as String?) ??
          (map['displayName'] as String?) ??
          '',
      username: (map['username'] as String?) ?? '',
      bio: map['bio'] as String?,
      avatarUrl: (map['avatar_url'] as String?) ??
          (map['avatarUrl'] as String?),
      streakCount: (map['streak_count'] as num?)?.toInt() ??
          (map['streakCount'] as num?)?.toInt() ??
          0,
      longestStreak: (map['longest_streak'] as num?)?.toInt() ??
          (map['longestStreak'] as num?)?.toInt() ??
          0,
      totalXp: (map['total_xp'] as num?)?.toInt() ??
          (map['totalXp'] as num?)?.toInt() ??
          0,
      level: (map['level'] as num?)?.toInt() ??
          (map['level'] as num?)?.toInt() ??
          1,
      unlockedBadgesCount: (map['unlocked_badges_count'] as num?)?.toInt() ??
          (map['unlockedBadgesCount'] as num?)?.toInt() ??
          0,
      lastStreakDate: (map['last_streak_date'] as String?) ??
          (map['lastStreakDate'] as String?),
      createdAt: (map['created_at'] as String?) ??
          (map['createdAt'] as String?) ??
          '',
    );
  }

  Map<String, dynamic> toMap({bool includePassword = false}) {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'email': email,
      if (includePassword && password.isNotEmpty) 'password': password,
      'display_name': displayName,
      'username': username,
      'bio': bio,
      'avatar_url': avatarUrl,
      'streak_count': streakCount,
      'longest_streak': longestStreak,
      'total_xp': totalXp,
      'level': level,
      'unlocked_badges_count': unlockedBadgesCount,
      'last_streak_date': lastStreakDate,
      'created_at': createdAt,
    };
  }

  /// Generates a Map representation specifically tailored for Cloud Firestore storage.
  /// Omits sensitive fields like [password] and excludes null values to keep documents clean.
  Map<String, dynamic> toFirestoreMap() {
    final map = toMap(includePassword: false);
    map.removeWhere((key, value) => value == null);
    return map;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      UserModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          password == other.password &&
          displayName == other.displayName &&
          username == other.username &&
          bio == other.bio &&
          avatarUrl == other.avatarUrl &&
          streakCount == other.streakCount &&
          longestStreak == other.longestStreak &&
          totalXp == other.totalXp &&
          level == other.level &&
          unlockedBadgesCount == other.unlockedBadgesCount &&
          lastStreakDate == other.lastStreakDate &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      displayName.hashCode ^
      username.hashCode ^
      email.hashCode ^
      password.hashCode ^
      bio.hashCode ^
      avatarUrl.hashCode ^
      streakCount.hashCode ^
      longestStreak.hashCode ^
      totalXp.hashCode ^
      level.hashCode ^
      unlockedBadgesCount.hashCode ^
      lastStreakDate.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName, streak: $streakCount, xp: $totalXp, level: $level, badges: $unlockedBadgesCount)';
  }
}
