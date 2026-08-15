import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_typography.dart';

/// Warning banner notifying toxicity caution for pets and humans.
class PlantToxicityBanner extends StatelessWidget {
  final String toxicity;

  const PlantToxicityBanner({super.key, required this.toxicity});

  @override
  Widget build(BuildContext context) {
    if (toxicity.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pastelRedBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.pastelRedText.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.pastelRedText,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Peringatan Keamanan',
                  style: AppTypography.headline.copyWith(
                    color: AppColors.pastelRedText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  toxicity,
                  style: AppTypography.footnoteRegular.copyWith(
                    color: AppColors.pastelRedText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
