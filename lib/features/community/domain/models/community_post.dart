import 'package:flutter/foundation.dart';
import 'package:plenty/features/profile/domain/models/badge_item.dart';

/// Domain entity representing a community post with optional image or attached achievement badge.
@immutable
class CommunityPost {
  final String id;
  final int? userId;
  final String? authorId;
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
    this.authorId,
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
    String? authorId,
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
      authorId: authorId ?? this.authorId,
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

  Map<String, dynamic> toFirestoreMap() => {
        'id': id,
        'user_id': authorId ?? userId?.toString() ?? '1',
        'author_name': authorName,
        'author_avatar_url': authorAvatar,
        'category': category,
        'caption': content,
        'image_url': imagePath,
        'badge_id': attachedBadge?.id,
        'badge_title': attachedBadge?.title,
        'badge_desc': attachedBadge?.desc,
        'badge_icon': attachedBadge?.iconName,
        'badge_tier': attachedBadge?.tierName,
        'badge_level': attachedBadge?.level,
        'badge_progress': attachedBadge?.progress,
        'badge_total': attachedBadge?.total,
        'badge_bg_hex': attachedBadge?.bgColorHex,
        'badge_accent_hex': attachedBadge?.accentColorHex,
        'badge_is_unlocked': attachedBadge?.isUnlocked == true ? 1 : 0,
        'badge_unlocked_at': attachedBadge?.unlockedDate,
        'kudos_count': likesCount,
        'comment_count': commentsCount,
        'created_at': createdAt.toIso8601String(),
      };

  factory CommunityPost.fromFirestoreMap(
    Map<String, dynamic> map, {
    String? currentUserId,
    bool isLiked = false,
  }) {
    final rawUserId = map['user_id']?.toString() ?? '1';
    final parsedIntId = int.tryParse(rawUserId);
    final isAuthor = currentUserId != null &&
        (currentUserId == rawUserId ||
            (parsedIntId != null && currentUserId == parsedIntId.toString()));
    final createdAtStr =
        map['created_at']?.toString() ?? DateTime.now().toIso8601String();
    final createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now();

    BadgeItem? attachedBadge;
    final badgeId = map['badge_id']?.toString();
    if (badgeId != null && badgeId.isNotEmpty) {
      attachedBadge = BadgeItem(
        id: badgeId,
        title: map['badge_title']?.toString() ?? '',
        desc: map['badge_desc']?.toString() ?? '',
        iconName: map['badge_icon']?.toString() ?? 'sprout',
        isUnlocked: map['badge_is_unlocked'] == 1 ||
            map['badge_is_unlocked'] == true,
        unlockedDate: map['badge_unlocked_at']?.toString(),
        level: (map['badge_level'] as num?)?.toInt() ?? 1,
        progress: (map['badge_progress'] as num?)?.toInt() ?? 1,
        total: (map['badge_total'] as num?)?.toInt() ?? 1,
        bgColorHex: map['badge_bg_hex']?.toString() ?? '#EBF7F1',
        accentColorHex: map['badge_accent_hex']?.toString() ?? '#2D6A4F',
        tierName: map['badge_tier']?.toString() ?? '',
      );
    }

    final rawImage = (map['image_url'] ??
            map['image_path'] ??
            map['imageUrl'] ??
            map['imagePath']) as String?;
    String? resolvedImage = rawImage?.trim();
    if (resolvedImage != null && resolvedImage.startsWith('gs://')) {
      final uri = Uri.tryParse(resolvedImage);
      if (uri != null && uri.host.isNotEmpty) {
        final bucket = uri.host;
        final path =
            uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
        resolvedImage =
            'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(path)}?alt=media';
      }
    }

    return CommunityPost(
      id: map['id']?.toString() ?? '',
      userId: parsedIntId ?? rawUserId.hashCode.abs(),
      authorId: rawUserId,
      authorName: (map['author_name'] as String?) ??
          (map['display_name'] as String?) ??
          'Penggemar Tanaman',
      authorAvatar: (map['author_avatar_url'] as String?) ??
          (map['avatar_url'] as String?),
      timeAgo: formatTimeAgo(createdAt),
      category: map['category'] as String? ?? 'pertanyaan',
      content:
          (map['caption'] as String?) ?? (map['content'] as String?) ?? '',
      imagePath: resolvedImage,
      attachedBadge: attachedBadge,
      likesCount: (map['kudos_count'] as num?)?.toInt() ??
          (map['likes_count'] as num?)?.toInt() ??
          0,
      isLiked: isLiked,
      isAuthor: isAuthor,
      commentsCount: (map['comment_count'] as num?)?.toInt() ??
          (map['comments_count'] as num?)?.toInt() ??
          0,
      createdAt: createdAt,
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
