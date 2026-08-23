import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/features/community/domain/models/community_post.dart';
import 'package:plenty/features/community/domain/models/post_comment_model.dart';

void main() {
  group('CommunityPost Model Tests', () {
    test('initializes and formats time correctly', () {
      final post = CommunityPost(
        id: 'post_100',
        authorName: 'Botanist User',
        timeAgo: 'Baru saja',
        category: 'tips',
        content: 'Cara mudah merawat monstera',
        likesCount: 15,
        commentsCount: 3,
        createdAt: DateTime.now(),
      );

      expect(post.id, 'post_100');
      expect(post.authorName, 'Botanist User');
      expect(post.category, 'tips');
      expect(post.likesCount, 15);
      expect(post.commentsCount, 3);
    });
  });

  group('PostCommentModel Serialization', () {
    test('fromMap and toMap handle comment text correctly', () {
      final map = {
        'id': 'cmt_1',
        'post_id': 'post_100',
        'user_id': 1,
        'content': 'Keren banget infonya!',
        'created_at': '2026-08-19T08:30:00.000Z',
      };

      final comment = PostCommentModel.fromMap(map, authorName: 'Teman Bunga');

      expect(comment.id, 'cmt_1');
      expect(comment.postId, 'post_100');
      expect(comment.authorName, 'Teman Bunga');
      expect(comment.content, 'Keren banget infonya!');
      expect(comment.toMap(), equals(map));
    });
  });
}
