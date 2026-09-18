import 'package:plenty/core/error/result.dart';
import 'package:plenty/features/community/domain/models/community_post.dart';
import 'package:plenty/features/community/domain/models/post_comment_model.dart';

/// Contract interface for Community Repository.
abstract interface class ICommunityRepository {
  /// Retrieves community posts optionally filtered by [category] for user [currentUserId].
  Future<Result<List<CommunityPost>>> getPosts({
    String category = 'all',
    int? currentUserId,
  });

  /// Toggles like state on a post for [userId].
  Future<Result<CommunityPost>> toggleLike(String postId, {int? userId});

  /// Creates a new community post associated with [userId].
  Future<Result<CommunityPost>> createPost(CommunityPost post, {int? userId});

  /// Updates an existing community post.
  Future<Result<CommunityPost>> updatePost(CommunityPost post, {int? userId});

  /// Deletes a community post by [postId].
  Future<Result<void>> deletePost(String postId, {int? userId});

  /// Checks if a user has already shared a specific [badgeId] to the community.
  Future<Result<bool>> hasUserSharedBadge(String badgeId, {int? userId});

  /// Retrieves comments for a specific post.
  Future<Result<List<PostCommentModel>>> getComments(String postId);

  /// Adds a new comment to a post.
  Future<Result<PostCommentModel>> addComment({
    required String postId,
    required String content,
    int? userId,
    String? authorName,
    String? authorAvatarUrl,
  });

  /// Deletes a comment by [commentId] from [postId].
  Future<Result<void>> deleteComment({
    required String postId,
    required String commentId,
    int? userId,
  });

  /// Uploads any pending offline posts stored in local storage to Firebase.
  Future<void> syncPendingPosts();

  /// Legacy helper for seeding initial mock/test posts if needed.
  Future<void> seedInitialPosts();
}
