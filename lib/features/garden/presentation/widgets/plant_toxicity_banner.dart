import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';

class PlantToxicityBanner extends StatelessWidget {
  final String toxicityInfo;

  const PlantToxicityBanner({super.key, required this.toxicityInfo});

  @override
  Widget build(BuildContext context) {
    if (toxicityInfo.isEmpty) return const SizedBox.shrink();

    final isToxic = toxicityInfo.toLowerCase().contains('beracun') ||
        toxicityInfo.toLowerCase().contains('toxic');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isToxic ? AppColors.pastelRedBg : AppColors.pastelGreenBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToxic ? AppColors.pastelRedText : AppColors.forest,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isToxic ? Icons.warning_amber_rounded : Icons.pets,
            color: isToxic ? AppColors.pastelRedText : AppColors.forest,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              toxicityInfo,
              style: AppTypography.footnoteRegular.copyWith(
                color: isToxic ? AppColors.pastelRedText : AppColors.forest,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
