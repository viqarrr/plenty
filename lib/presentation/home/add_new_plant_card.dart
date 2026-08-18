import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';

class AddNewPlantCard extends StatelessWidget {
  final VoidCallback onTap;

  const AddNewPlantCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.canvasDefault,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.forest.withValues(alpha: 0.3),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.pastelGreenBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppColors.forest, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              'Tambah Tanaman',
              style: AppTypography.calloutBold.copyWith(
                color: AppColors.forest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
