import 'package:flutter/foundation.dart';

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

  factory PostCommentModel.fromMap(
    Map<String, dynamic> map, {
    String? authorName,
    String? authorAvatarUrl,
  }) {
    return PostCommentModel(
      id: map['id'] as String,
      postId: map['post_id'] as String,
      userId: map['user_id']?.toString() ?? '1',
      authorName:
          authorName ?? (map['display_name'] as String?) ?? 'Teman Plenty',
      authorAvatarUrl: authorAvatarUrl ?? (map['avatar_url'] as String?),
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'post_id': postId,
        'user_id': int.tryParse(userId) ?? 1,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };

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
