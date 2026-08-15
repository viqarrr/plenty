import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_typography.dart';

/// Card in plant grid for adding a new custom plant.
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
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.forest.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.forest.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppColors.forest, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              'Add New',
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
