import 'package:flutter/foundation.dart';
import 'package:plenty/core/di/injector.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/community/domain/models/community_post.dart';
import 'package:plenty/features/community/domain/repositories/community_repository.dart';
import 'package:plenty/features/profile/domain/models/badge_item.dart';

/// State Management Controller for Community Feed, Category Filtering, Likes, and Post Creation.
class CommunityController extends ChangeNotifier {
  final ICommunityRepository _repository;

  String _selectedCategory = 'all'; // 'all', 'pertanyaan', 'pencapaian', 'tips'
  List<CommunityPost> _posts = const [];
  bool _isLoading = false;
  String? _errorMessage;

  CommunityController({ICommunityRepository? repository})
    : _repository = repository ?? Injector.communityRepository;

  String get selectedCategory => _selectedCategory;
  List<CommunityPost> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Loads community posts from SQLite based on the currently selected category filter.
  Future<void> loadPosts({String? category}) async {
    if (category != null) {
      _selectedCategory = category;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getPosts(category: _selectedCategory);
    switch (result) {
      case Success(:final data):
        _posts = data;
        _isLoading = false;
        notifyListeners();
      case Error(:final failure):
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
    }
  }

  /// Sets the active category filter ('all', 'pertanyaan', 'pencapaian', 'tips') and refreshes the feed.
  Future<void> setCategory(String category) async {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    await loadPosts(category: category);
  }

  /// Toggles like on a post and updates local state optimistically.
  Future<void> toggleLike(String postId) async {
    // Optimistic UI update
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final currentPost = _posts[index];
    final nextLiked = !currentPost.isLiked;
    final nextCount = nextLiked
        ? currentPost.likesCount + 1
        : (currentPost.likesCount - 1).clamp(0, 999999);

    final updatedList = List<CommunityPost>.from(_posts);
    updatedList[index] = currentPost.copyWith(
      isLiked: nextLiked,
      likesCount: nextCount,
    );
    _posts = updatedList;
    notifyListeners();

    final result = await _repository.toggleLike(postId);
    switch (result) {
      case Success(:final data):
        final finalIndex = _posts.indexWhere((p) => p.id == postId);
        if (finalIndex != -1) {
          final finalList = List<CommunityPost>.from(_posts);
          finalList[finalIndex] = data;
          _posts = finalList;
          notifyListeners();
        }
      case Error(:final failure):
        _errorMessage = failure.message;
        final revertIndex = _posts.indexWhere((p) => p.id == postId);
        if (revertIndex != -1) {
          final revertList = List<CommunityPost>.from(_posts);
          revertList[revertIndex] = currentPost;
          _posts = revertList;
          notifyListeners();
        }
    }
  }

  /// Creates and submits a new community post.
  Future<CommunityPost?> createPost({
    required String category,
    required String content,
    String? imagePath,
    BadgeItem? attachedBadge,
    String? authorName,
    String? authorAvatar,
  }) async {
    try {
      String finalAuthor = authorName ?? '';
      String? finalAvatar = authorAvatar;

      if (finalAuthor.isEmpty ||
          finalAuthor == 'Pecinta Tanaman' ||
          finalAuthor == 'Penggemar Tanaman') {
        try {
          final user = await PreferenceHandler.getUser();
          if (user != null) {
            if (user.username.isNotEmpty) {
              finalAuthor = user.username;
            } else if (user.displayName.isNotEmpty) {
              finalAuthor = user.displayName;
            }
            finalAvatar = user.avatarUrl;
          }
        } catch (_) {}
      }

      if (finalAuthor.isEmpty) {
        finalAuthor = 'Penggemar Tanaman';
      }

      final newPost = CommunityPost(
        id: 'cp_${DateTime.now().millisecondsSinceEpoch}',
        authorName: finalAuthor,
        authorAvatar: finalAvatar,
        timeAgo: 'Baru saja',
        category: category,
        content: content,
        imagePath: imagePath,
        attachedBadge: attachedBadge,
        likesCount: 0,
        isLiked: false,
        commentsCount: 0,
        createdAt: DateTime.now(),
      );

      final result = await _repository.createPost(newPost);
      switch (result) {
        case Success(:final data):
          await loadPosts();
          return data;
        case Error(:final failure):
          _errorMessage = failure.message;
          notifyListeners();
          return null;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Updates an existing community post's category, content, or image.
  Future<CommunityPost?> editPost({
    required String postId,
    required String category,
    required String content,
    String? imagePath,
  }) async {
    try {
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index == -1) return null;

      final existingPost = _posts[index];
      final updatedDraft = existingPost.copyWith(
        category: category,
        content: content,
        imagePath: imagePath,
      );

      final user = await PreferenceHandler.getUser();
      final result = await _repository.updatePost(
        updatedDraft,
        userId: user?.id,
      );
      switch (result) {
        case Success(:final data):
          await loadPosts();
          return data;
        case Error(:final failure):
          _errorMessage = failure.message;
          notifyListeners();
          return null;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Deletes a community post by [postId].
  Future<bool> deletePost(String postId) async {
    try {
      final user = await PreferenceHandler.getUser();
      final result = await _repository.deletePost(postId, userId: user?.id);
      switch (result) {
        case Success():
          _posts = _posts.where((p) => p.id != postId).toList();
          notifyListeners();
          return true;
        case Error(:final failure):
          _errorMessage = failure.message;
          notifyListeners();
          return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
