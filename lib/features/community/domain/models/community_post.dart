import 'package:flutter/foundation.dart';
import 'package:plenty/features/profile/domain/models/badge_item.dart';

/// Domain entity representing a community post with optional image or attached achievement badge.
@immutable
class CommunityPost {
  final String id;
  final int? userId;
  final String authorName;
  final String? authorAvatar;
  final String timeAgo;
  final String category; // 'pertanyaan', 'pencapaian', 'tips'
  final String content;
  final String? imagePath;
  final BadgeItem? attachedBadge;
  final int likesCount;
  final bool isLiked;
  final bool isAuthor;
  final int commentsCount;
  final DateTime createdAt;

  const CommunityPost({
    required this.id,
    this.userId,
    required this.authorName,
    this.authorAvatar,
    required this.timeAgo,
    required this.category,
    required this.content,
    this.imagePath,
    this.attachedBadge,
    this.likesCount = 0,
    this.isLiked = false,
    this.isAuthor = false,
    this.commentsCount = 0,
    required this.createdAt,
  });

  CommunityPost copyWith({
    String? id,
    int? userId,
    String? authorName,
    String? authorAvatar,
    String? timeAgo,
    String? category,
    String? content,
    String? imagePath,
    BadgeItem? attachedBadge,
    int? likesCount,
    bool? isLiked,
    bool? isAuthor,
    int? commentsCount,
    DateTime? createdAt,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      timeAgo: timeAgo ?? this.timeAgo,
      category: category ?? this.category,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      attachedBadge: attachedBadge ?? this.attachedBadge,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      isAuthor: isAuthor ?? this.isAuthor,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}j lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}h lalu';
    } else {
      return '${dateTime.day} ${_monthName(dateTime.month)}';
    }
  }

  static String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunityPost &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
