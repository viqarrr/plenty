import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/features/forum/domain/models/community_post_model.dart';

class SocialPostCard extends StatelessWidget {
  final CommunityPostModel post;
  final VoidCallback onKudos;
  final VoidCallback? onComment;

  const SocialPostCard({
    super.key,
    required this.post,
    required this.onKudos,
    this.onComment,
  });

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays} hari lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes} menit lalu';
    return 'Baru saja';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.pastelGreenBg,
                child: Text(
                  post.authorName.isNotEmpty ? post.authorName[0] : 'U',
                  style: AppTypography.footnoteBold.copyWith(
                    color: AppColors.forest,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: AppTypography.calloutBold.copyWith(fontSize: 14),
                    ),
                    Text(
                      '${post.category} • ${_formatTimeAgo(post.createdAt)}',
                      style: AppTypography.caption1Regular.copyWith(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.pastelGreenBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  post.category,
                  style: AppTypography.caption2Bold.copyWith(
                    color: AppColors.forest,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (post.caption != null && post.caption!.isNotEmpty) ...[
            Text(
              post.caption!,
              style: AppTypography.bodyRegular.copyWith(
                color: AppColors.inkSoft,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              InkWell(
                onTap: onKudos,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        post.isLikedByMe
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 18,
                        color: post.isLikedByMe
                            ? AppColors.error
                            : AppColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.kudosCount}',
                        style: AppTypography.caption1Regular.copyWith(
                          color: post.isLikedByMe
                              ? AppColors.error
                              : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: onComment,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 18,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.commentCount}',
                        style: AppTypography.caption1Regular.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
