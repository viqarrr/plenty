import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';

class SocialPostCard extends StatelessWidget {
  final String authorName;
  final String timeAgo;
  final String plantName;
  final String content;
  final int likesCount;
  final int commentsCount;

  const SocialPostCard({
    super.key,
    required this.authorName,
    required this.timeAgo,
    required this.plantName,
    required this.content,
    required this.likesCount,
    required this.commentsCount,
  });

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
                  authorName.isNotEmpty ? authorName[0] : 'U',
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
                      authorName,
                      style: AppTypography.calloutBold.copyWith(fontSize: 14),
                    ),
                    Text(
                      '$plantName • $timeAgo',
                      style: AppTypography.caption1Regular.copyWith(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: AppTypography.bodyRegular.copyWith(
              color: AppColors.inkSoft,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.favorite_border, size: 18, color: AppColors.muted),
              const SizedBox(width: 4),
              Text(
                '$likesCount',
                style: AppTypography.caption1Regular.copyWith(
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(width: 20),
              Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.muted),
              const SizedBox(width: 4),
              Text(
                '$commentsCount',
                style: AppTypography.caption1Regular.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
