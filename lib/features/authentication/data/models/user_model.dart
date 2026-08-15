import 'package:plenty/features/authentication/domain/entities/user_entity.dart';

/// Data Transfer Object (DTO) for User database serialization.
class UserModel extends UserEntity {
  const UserModel({
    super.id,
    required super.email,
    required super.password,
    required super.displayName,
    required super.username,
    super.bio,
    super.avatarUrl,
    super.createdAt,
  });

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      password: entity.password,
      displayName: entity.displayName,
      username: entity.username,
      bio: entity.bio,
      avatarUrl: entity.avatarUrl,
      createdAt: entity.createdAt,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toString(),
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
      'bio': avatarUrl,
      'avatar_url': avatarUrl,
      'created_at': createdAt,
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      password: password,
      displayName: displayName,
      username: username,
      bio: bio,
      avatarUrl: avatarUrl,
      createdAt: createdAt,
    );
  }
}
