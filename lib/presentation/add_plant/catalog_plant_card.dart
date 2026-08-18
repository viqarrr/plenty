import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/data/models/plant_model.dart';

class CatalogPlantCard extends StatelessWidget {
  final PlantModel plant;
  final VoidCallback onTap;

  const CatalogPlantCard({super.key, required this.plant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isEasyCare =
        plant.careLevel.toUpperCase().contains('EASY') ||
        plant.careLevel.toUpperCase().contains('MUDAH') ||
        plant.careLevel.toUpperCase().contains('LOW');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Thumbnail / Icon Container
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.forest.withValues(alpha: 0.1),
                        AppColors.emerald.withValues(alpha: 0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: (plant.imageUrl != null && plant.imageUrl!.isNotEmpty)
                      ? Image.network(
                          plant.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.local_florist,
                            color: AppColors.forest,
                            size: 28,
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.forest,
                                ),
                              ),
                            );
                          },
                        )
                      : const Icon(
                          Icons.local_florist,
                          color: AppColors.forest,
                          size: 28,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Plant Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plant.name,
                            style: AppTypography.headline.copyWith(
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'LOCAL',
                            style: AppTypography.caption1Bold.copyWith(
                              fontSize: 10,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plant.scientificName,
                      style: AppTypography.footnoteRegular.copyWith(
                        color: AppColors.muted,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    // Badges (Care Level & Toxicity)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isEasyCare
                                ? AppColors.pastelGreenBg
                                : AppColors.pastelYellowBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            plant.careLevel,
                            style: AppTypography.caption1Bold.copyWith(
                              color: isEasyCare
                                  ? AppColors.pastelGreenText
                                  : AppColors.pastelYellowText,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        if (plant.toxicity.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.pastelRedBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'TOXIC',
                              style: AppTypography.caption1Bold.copyWith(
                                color: AppColors.pastelRedText,
                                fontSize: 9,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
