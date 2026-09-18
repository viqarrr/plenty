import 'package:plenty/features/community/data/datasources/community_remote_datasource.dart';
import 'package:plenty/features/community/domain/models/community_post.dart';
import 'package:plenty/features/community/domain/models/post_comment_model.dart';

/// In-memory fake implementation of [CommunityRemoteDataSource] for isolated unit & widget tests.
class FakeCommunityRemoteDataSource implements CommunityRemoteDataSource {
  final Map<String, CommunityPost> posts = {};
  final Map<String, List<PostCommentModel>> comments = {};
  final Map<String, Set<String>> likes = {};

  bool shouldThrowOnSave = false;
  bool shouldThrowOnGet = false;

  @override
  Future<List<CommunityPost>> getPosts({
    String category = 'all',
    String? currentUserId,
  }) async {
    if (shouldThrowOnGet) {
      throw Exception('Network unavailable');
    }
    var list = posts.values.toList();
    final lower = category.toLowerCase().trim();
    if (lower != 'all' && lower != 'semua') {
      list = list.where((p) => p.category.toLowerCase() == lower).toList();
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.map((p) {
      final isLiked = currentUserId != null &&
          (likes[p.id]?.contains(currentUserId) ?? false);
      return p.copyWith(
        isLiked: isLiked,
        likesCount: likes[p.id]?.length ?? p.likesCount,
      );
    }).toList();
  }

  @override
  Future<CommunityPost?> getPostById(String postId, {String? currentUserId}) async {
    final post = posts[postId];
    if (post == null) return null;
    final isLiked = currentUserId != null &&
        (likes[postId]?.contains(currentUserId) ?? false);
    final isAuthor = currentUserId != null &&
        (post.authorId == currentUserId ||
            (post.userId != null && post.userId.toString() == currentUserId));
    return post.copyWith(
      isLiked: isLiked,
      isAuthor: isAuthor || post.isAuthor,
      likesCount: likes[postId]?.length ?? post.likesCount,
    );
  }

  @override
  Future<void> savePost(CommunityPost post, {String? userId}) async {
    if (shouldThrowOnSave) {
      throw Exception('Network error during savePost');
    }
    posts[post.id] = post.copyWith(
      authorId: userId ?? post.authorId,
    );
  }

  @override
  Future<void> updatePost(CommunityPost post, {String? userId}) async {
    final existing = posts[post.id];
    if (existing != null) {
      posts[post.id] = existing.copyWith(
        category: post.category,
        content: post.content,
        imagePath: post.imagePath,
      );
    }
  }

  @override
  Future<void> deletePost(String postId, {String? userId}) async {
    posts.remove(postId);
    comments.remove(postId);
    likes.remove(postId);
  }

  @override
  Future<bool> toggleLike(String postId, String userId) async {
    final userLikes = likes.putIfAbsent(postId, () => <String>{});
    if (userLikes.contains(userId)) {
      userLikes.remove(userId);
      final p = posts[postId];
      if (p != null) {
        posts[postId] =
            p.copyWith(likesCount: (p.likesCount - 1).clamp(0, 999999));
      }
      return false;
    } else {
      userLikes.add(userId);
      final p = posts[postId];
      if (p != null) {
        posts[postId] = p.copyWith(likesCount: p.likesCount + 1);
      }
      return true;
    }
  }

  @override
  Future<bool> isPostLikedByUser(String postId, String userId) async {
    return likes[postId]?.contains(userId) ?? false;
  }

  @override
  Future<List<PostCommentModel>> getComments(String postId) async {
    final list = comments[postId] ?? [];
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.from(list);
  }

  @override
  Future<void> saveComment(PostCommentModel comment) async {
    final list = comments.putIfAbsent(comment.postId, () => []);
    list.add(comment);
    final p = posts[comment.postId];
    if (p != null) {
      posts[comment.postId] = p.copyWith(commentsCount: p.commentsCount + 1);
    }
  }

  @override
  Future<void> deleteComment(String postId, String commentId) async {
    final list = comments[postId];
    if (list != null) {
      list.removeWhere((c) => c.id == commentId);
      final p = posts[postId];
      if (p != null) {
        posts[postId] = p.copyWith(
          commentsCount: (p.commentsCount - 1).clamp(0, 999999),
        );
      }
    }
  }

  @override
  Future<bool> hasUserSharedBadge(String badgeId, String userId) async {
    return posts.values.any((p) =>
        ((p.authorId == userId) || (p.userId?.toString() == userId)) &&
        (p.attachedBadge?.id == badgeId));
  }
}
