import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/xp_config.dart';
import 'package:plenty/core/theme/app_typography.dart';

/// "PROGRES SAAT INI" section card displaying real level, XP progress bar,
/// and tier labels queried from SQLite.
class CurrentProgressCard extends StatelessWidget {
  final int userLevel;
  final int totalXp;

  const CurrentProgressCard({
    super.key,
    this.userLevel = 1,
    this.totalXp = 0,
  });

  @override
  Widget build(BuildContext context) {
    final xpInCurrentLevel = totalXp % XpConfig.xpPerLevel;
    final xpToNextLevel = XpConfig.xpPerLevel - xpInCurrentLevel;
    final progress = (xpInCurrentLevel / XpConfig.xpPerLevel.toDouble()).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            // Level and XP text row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Level $userLevel',
                  style: AppTypography.headlineSemiBold,
                ),
                Text(
                  '$xpToNextLevel XP menuju Level ${userLevel + 1}',
                  style: AppTypography.caption1Regular.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
        
            // Dynamic Linear progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppColors.canvasDefault,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sprout),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
