import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plenty/features/community/domain/models/community_post.dart';
import 'package:plenty/features/community/domain/models/post_comment_model.dart';

/// Contract interface for Community Forum posts, likes, and comments in Cloud Firestore.
abstract interface class CommunityRemoteDataSource {
  /// Fetches community posts optionally filtered by [category].
  /// Evaluates `isLiked` for [currentUserId] if provided.
  Future<List<CommunityPost>> getPosts({
    String category = 'all',
    String? currentUserId,
  });

  /// Saves or upserts a post document in Firestore collection `community_posts/{postId}`.
  Future<void> savePost(CommunityPost post, {String? userId});

  /// Updates an existing post in Firestore collection `community_posts/{postId}`.
  Future<void> updatePost(CommunityPost post, {String? userId});

  /// Deletes a community post document.
  Future<void> deletePost(String postId, {String? userId});

  /// Toggles like state under `community_posts/{postId}/likes/{userId}`
  /// and updates `kudos_count` on the post document.
  /// Returns `true` if liked, `false` if unliked.
  Future<bool> toggleLike(String postId, String userId);

  /// Checks if [userId] has liked [postId].
  Future<bool> isPostLikedByUser(String postId, String userId);

  /// Retrieves comments for [postId] from `community_posts/{postId}/comments`.
  Future<List<PostCommentModel>> getComments(String postId);

  /// Saves a comment to `community_posts/{postId}/comments/{commentId}`
  /// and updates `comment_count` on the post document.
  Future<void> saveComment(PostCommentModel comment);

  /// Deletes a comment from `community_posts/{postId}/comments/{commentId}`
  /// and decrements `comment_count` on the post document.
  Future<void> deleteComment(String postId, String commentId);

  /// Checks if [userId] has shared [badgeId] to the community.
  Future<bool> hasUserSharedBadge(String badgeId, String userId);
}

/// Concrete implementation of [CommunityRemoteDataSource] backed by Cloud Firestore.
class FirestoreCommunityRemoteDataSourceImpl implements CommunityRemoteDataSource {
  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  static const String postsCollection = 'community_posts';
  static const String likesSubcollection = 'likes';
  static const String commentsSubcollection = 'comments';

  FirestoreCommunityRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  @override
  Future<List<CommunityPost>> getPosts({
    String category = 'all',
    String? currentUserId,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(postsCollection);

    final normalizedCategory = _normalizeCategory(category);
    if (normalizedCategory != null) {
      query = query.where('category', isEqualTo: normalizedCategory);
    }

    final querySnap = await query.get();

    final posts = <CommunityPost>[];
    for (final doc in querySnap.docs) {
      final data = doc.data();
      bool isLiked = false;

      if (currentUserId != null && currentUserId.isNotEmpty) {
        try {
          final likeSnap = await _firestore
              .collection(postsCollection)
              .doc(doc.id)
              .collection(likesSubcollection)
              .doc(currentUserId)
              .get();
          isLiked = likeSnap.exists;
        } catch (_) {}
      }

      posts.add(CommunityPost.fromFirestoreMap(
        data,
        currentUserId: currentUserId,
        isLiked: isLiked,
      ));
    }

    // Sort in memory by createdAt descending
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return posts;
  }

  @override
  Future<void> savePost(CommunityPost post, {String? userId}) async {
    final data = post.toFirestoreMap();
    if (userId != null && userId.isNotEmpty) {
      data['user_id'] = userId;
    }
    await _firestore
        .collection(postsCollection)
        .doc(post.id)
        .set(data, SetOptions(merge: true));
  }

  @override
  Future<void> updatePost(CommunityPost post, {String? userId}) async {
    final updateData = <String, dynamic>{
      'category': post.category,
      'caption': post.content,
      'image_url': post.imagePath,
    };
    await _firestore
        .collection(postsCollection)
        .doc(post.id)
        .set(updateData, SetOptions(merge: true));
  }

  @override
  Future<void> deletePost(String postId, {String? userId}) async {
    await _firestore.collection(postsCollection).doc(postId).delete();
  }

  @override
  Future<bool> toggleLike(String postId, String userId) async {
    final postDoc = _firestore.collection(postsCollection).doc(postId);
    final likeDoc = postDoc.collection(likesSubcollection).doc(userId);

    final likeSnap = await likeDoc.get();

    if (likeSnap.exists) {
      await likeDoc.delete();
      try {
        await postDoc.set(
          {'kudos_count': FieldValue.increment(-1)},
          SetOptions(merge: true),
        );
      } catch (_) {}
      return false;
    } else {
      await likeDoc.set(
        {
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
      try {
        await postDoc.set(
          {'kudos_count': FieldValue.increment(1)},
          SetOptions(merge: true),
        );
      } catch (_) {}
      return true;
    }
  }

  @override
  Future<bool> isPostLikedByUser(String postId, String userId) async {
    final likeSnap = await _firestore
        .collection(postsCollection)
        .doc(postId)
        .collection(likesSubcollection)
        .doc(userId)
        .get();
    return likeSnap.exists;
  }

  @override
  Future<List<PostCommentModel>> getComments(String postId) async {
    final querySnap = await _firestore
        .collection(postsCollection)
        .doc(postId)
        .collection(commentsSubcollection)
        .get();

    final comments = querySnap.docs
        .map((doc) => PostCommentModel.fromMap(doc.data()))
        .toList();

    // Sort in memory by createdAt ascending
    comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return comments;
  }

  @override
  Future<void> saveComment(PostCommentModel comment) async {
    final postDoc = _firestore.collection(postsCollection).doc(comment.postId);
    final commentDoc = postDoc.collection(commentsSubcollection).doc(comment.id);

    await commentDoc.set(comment.toFirestoreMap(), SetOptions(merge: true));

    try {
      await postDoc.set(
        {'comment_count': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  @override
  Future<void> deleteComment(String postId, String commentId) async {
    final postDoc = _firestore.collection(postsCollection).doc(postId);
    await postDoc.collection(commentsSubcollection).doc(commentId).delete();

    try {
      await postDoc.set(
        {'comment_count': FieldValue.increment(-1)},
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  @override
  Future<bool> hasUserSharedBadge(String badgeId, String userId) async {
    final querySnap = await _firestore
        .collection(postsCollection)
        .where('user_id', isEqualTo: userId)
        .where('badge_id', isEqualTo: badgeId)
        .limit(1)
        .get();

    return querySnap.docs.isNotEmpty;
  }

  static String? _normalizeCategory(String? category) {
    if (category == null) return null;
    final lower = category.toLowerCase().trim();
    if (lower == 'all' || lower == 'semua') return null;
    if (lower.contains('tanya') || lower == 'pertanyaan') return 'pertanyaan';
    if (lower.contains('capai') || lower == 'pencapaian') return 'pencapaian';
    if (lower.contains('tip') || lower == 'tips') return 'tips';
    return lower;
  }
}
