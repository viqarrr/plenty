import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';

/// Clean Level & XP Progress bar extracted from PlantDetailsScreen.
class LevelXpBar extends StatelessWidget {
  final PlantModel plant;

  const LevelXpBar({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    final progress = (plant.xp % 100) / 100.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level ${plant.level}',
              style: AppTypography.footnoteBold.copyWith(color: AppColors.ink),
            ),
            Text(
              '${plant.xp % 100} / 100 XP',
              style: AppTypography.caption1Regular.copyWith(
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
          color: AppColors.forest,
          backgroundColor: AppColors.borderSubtle,
        ),
      ],
    );
  }
}
