import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_typography.dart';

/// Community social post card widget.
class SocialPostCard extends StatelessWidget {
  final String author;
  final String time;
  final String content;
  final String plantTag;

  const SocialPostCard({
    super.key,
    required this.author,
    required this.time,
    required this.content,
    required this.plantTag,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.forest.withValues(alpha: 0.1),
                  child: Text(
                    author.isNotEmpty ? author[0] : 'U',
                    style: const TextStyle(
                      color: AppColors.forest,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      style: AppTypography.headline.copyWith(fontSize: 15),
                    ),
                    Text(
                      time,
                      style: AppTypography.caption1Regular.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Chip(
                  label: Text(plantTag),
                  labelStyle: AppTypography.caption1Bold.copyWith(
                    color: AppColors.forest,
                  ),
                  backgroundColor: AppColors.pastelGreenBg,
                  side: BorderSide.none,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: AppTypography.bodyRegular.copyWith(
                fontSize: 14,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.thumb_up_alt_outlined,
                  size: 18,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 6),
                Text(
                  'Like',
                  style: AppTypography.footnoteRegular.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(width: 24),
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 18,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 6),
                Text(
                  'Komentar',
                  style: AppTypography.footnoteRegular.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
