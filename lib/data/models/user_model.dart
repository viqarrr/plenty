import 'package:flutter/foundation.dart';

/// Consolidated Data Model representing a registered User profile.
@immutable
class UserModel {
  final int? id;
  final String email;
  final String password;
  final String displayName;
  final String username;
  final String? bio;
  final String? avatarUrl;
  final String? createdAt;

  const UserModel({
    this.id,
    required this.email,
    required this.password,
    required this.displayName,
    required this.username,
    this.bio,
    this.avatarUrl,
    this.createdAt,
  });

  UserModel copyWith({
    int? id,
    String? email,
    String? password,
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
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
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] != null ? (map['id'] is int ? map['id'] as int : int.tryParse(map['id'].toString())) : null,
      email: (map['email'] as String?) ?? '',
      password: (map['password'] as String?) ?? '',
      displayName: (map['display_name'] as String?) ?? '',
      username: (map['username'] as String?) ?? '',
      bio: map['bio'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      createdAt: (map['created_at'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'email': email,
      'password': password,
      'display_name': displayName,
      'username': username,
      'bio': bio,
      'avatar_url': avatarUrl,
      'created_at': createdAt,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel.fromMap(json);

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

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName, username: $username)';
  }
}
