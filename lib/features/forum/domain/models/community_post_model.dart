import 'package:flutter/foundation.dart';

/// Data Model representing a community forum post.
@immutable
class CommunityPostModel {
  final String id;
  final String userId;
  final String authorName;
  final String? authorAvatarUrl;
  final String category;
  final String? caption;
  final String? imageUrl;
  final int kudosCount;
  final int commentCount;
  final DateTime createdAt;
  final bool isLikedByMe;

  const CommunityPostModel({
    required this.id,
    required this.userId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.category,
    this.caption,
    this.imageUrl,
    this.kudosCount = 0,
    this.commentCount = 0,
    required this.createdAt,
    this.isLikedByMe = false,
  });

  factory CommunityPostModel.fromMap(
    Map<String, dynamic> map, {
    String? authorName,
    String? authorAvatarUrl,
    bool isLikedByMe = false,
  }) {
    return CommunityPostModel(
      id: map['id'] as String,
      userId: map['user_id']?.toString() ?? '1',
      authorName:
          authorName ?? (map['display_name'] as String?) ?? 'Penggemar Tanaman',
      authorAvatarUrl: authorAvatarUrl ?? (map['avatar_url'] as String?),
      category: map['category'] as String,
      caption: map['caption'] as String?,
      imageUrl: map['image_url'] as String?,
      kudosCount: (map['kudos_count'] as int?) ?? 0,
      commentCount: (map['comment_count'] as int?) ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      isLikedByMe: isLikedByMe,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': int.tryParse(userId) ?? 1,
        'category': category,
        'caption': caption,
        'image_url': imageUrl,
        'kudos_count': kudosCount,
        'comment_count': commentCount,
        'created_at': createdAt.toIso8601String(),
      };

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) =>
      CommunityPostModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  CommunityPostModel copyWith({
    String? id,
    String? userId,
    String? authorName,
    String? authorAvatarUrl,
    String? category,
    String? caption,
    String? imageUrl,
    int? kudosCount,
    int? commentCount,
    DateTime? createdAt,
    bool? isLikedByMe,
  }) {
    return CommunityPostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      category: category ?? this.category,
      caption: caption ?? this.caption,
      imageUrl: imageUrl ?? this.imageUrl,
      kudosCount: kudosCount ?? this.kudosCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunityPostModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CommunityPostModel(id: $id, author: $authorName, category: $category)';
}
