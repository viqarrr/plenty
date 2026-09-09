import 'package:flutter/foundation.dart';
import 'package:plenty/features/community/domain/models/community_post.dart';

/// Data Model representing a comment on a community forum post.
@immutable
class PostCommentModel {
  final String id;
  final String postId;
  final String userId;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final DateTime createdAt;

  const PostCommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.content,
    required this.createdAt,
  });

  String get timeAgo => CommunityPost.formatTimeAgo(createdAt);

  factory PostCommentModel.fromMap(
    Map<String, dynamic> map, {
    String? authorName,
    String? authorAvatarUrl,
  }) {
    return PostCommentModel(
      id: map['id']?.toString() ?? '',
      postId: map['post_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '1',
      authorName: authorName ??
          (map['author_name'] as String?) ??
          (map['display_name'] as String?) ??
          'Teman Plenty',
      authorAvatarUrl: authorAvatarUrl ??
          (map['author_avatar_url'] as String?) ??
          (map['avatar_url'] as String?),
      content: map['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'post_id': postId,
        'user_id': int.tryParse(userId) ?? 1,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toFirestoreMap() => {
        'id': id,
        'post_id': postId,
        'user_id': userId,
        'author_name': authorName,
        'author_avatar_url': authorAvatarUrl,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };

  PostCommentModel copyWith({
    String? id,
    String? postId,
    String? userId,
    String? authorName,
    String? authorAvatarUrl,
    String? content,
    DateTime? createdAt,
  }) {
    return PostCommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory PostCommentModel.fromJson(Map<String, dynamic> json) =>
      PostCommentModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostCommentModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PostCommentModel(id: $id, author: $authorName, content: $content)';
}
