import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/features/forum/domain/models/community_post_model.dart';
import 'package:plenty/features/forum/domain/models/post_comment_model.dart';

void main() {
  group('CommunityPostModel Serialization', () {
    test('fromMap and toMap handle all fields accurately', () {
      final map = {
        'id': 'post_100',
        'user_id': 1,
        'category': 'Tips & Trik',
        'caption': 'Cara mudah merawat monstera',
        'image_url': null,
        'kudos_count': 15,
        'comment_count': 3,
        'created_at': '2026-08-19T08:00:00.000Z',
      };

      final model = CommunityPostModel.fromMap(map, authorName: 'Botanist User');

      expect(model.id, 'post_100');
      expect(model.authorName, 'Botanist User');
      expect(model.category, 'Tips & Trik');
      expect(model.kudosCount, 15);
      expect(model.commentCount, 3);
      expect(model.toMap(), equals(map));
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
