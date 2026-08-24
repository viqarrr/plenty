import 'package:plenty/core/error/result.dart';
import 'package:plenty/features/community/domain/models/community_post.dart';

/// Contract interface for Community Repository.
abstract interface class ICommunityRepository {
  /// Seeds initial discussions and prepares database migrations.
  Future<Result<void>> seedInitialPosts();

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
}
