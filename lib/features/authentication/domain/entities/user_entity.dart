import 'package:flutter/foundation.dart';

/// Domain Entity representing a registered User profile.
@immutable
class UserEntity {
  final String? id;
  final String email;
  final String password;
  final String displayName;
  final String username;
  final String? bio;
  final String? avatarUrl;
  final String? createdAt;

  const UserEntity({
    this.id,
    required this.displayName,
    required this.username,
    required this.email,
    required this.password,
    this.bio,
    this.avatarUrl,
    this.createdAt,
  });

  UserEntity copyWith({
    String? id,
    String? email,
    String? password,
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          password == other.password &&
          displayName == other.displayName &&
          username == other.username &&
          bio == other.bio &&
          avatarUrl == other.avatarUrl &&
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
      createdAt.hashCode;
}
