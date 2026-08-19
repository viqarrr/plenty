import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/data/models/plant_catalog_model.dart';

/// Reusable card widget for displaying a botanical plant species in the catalog selection list.
class CatalogPlantCard extends StatelessWidget {
  final PlantCatalogModel species;
  final bool isSelected;
  final VoidCallback onTap;

  const CatalogPlantCard({
    super.key,
    required this.species,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final careLevel = species.careLevel ?? 'Easy Care';
    final isEasyCare =
        careLevel.toUpperCase().contains('EASY') ||
        careLevel.toUpperCase().contains('MUDAH') ||
        careLevel.toUpperCase().contains('LOW');

    final imageUrl = species.imageUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.pastelGreenBg : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 96,
                    height: 96,
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
                    child: (imageUrl != null && imageUrl.isNotEmpty)
                        ? Image.network(
                            imageUrl,
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

                // Plant Details (Space-Between Dinamis)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment
                        .spaceBetween, // 2. Kunci space-between
                    children: [
                      // Top Section: Names
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            species.commonName,
                            style: AppTypography.bodyRegular.copyWith(
                              color: isSelected
                                  ? AppColors.forest
                                  : AppColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (species.scientificName != null &&
                              species.scientificName!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              species.scientificName!,
                              style: AppTypography.footnoteRegular.copyWith(
                                color: AppColors.muted,
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),

                      // Bottom Section: Badges
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildBadge(
                            careLevel,
                            isEasyCare
                                ? AppColors.pastelGreenBg
                                : AppColors.pastelYellowBg,
                            isEasyCare
                                ? AppColors.pastelGreenText
                                : AppColors.pastelYellowText,
                          ),
                          _buildBadge(
                            'Siram setiap ${species.defaultWateringInterval} hari',
                            AppColors.pastelBlueBg,
                            AppColors.pastelBlueText,
                          ),
                          _buildBadge(
                            species.isToxic ? 'Beracun' : 'Pet Friendly',
                            species.isToxic
                                ? AppColors.pastelRedBg
                                : AppColors.petFriendlyBg,
                            species.isToxic
                                ? AppColors.pastelRedText
                                : AppColors.petFriendlyText,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Center(
                      child: Icon(
                        Icons.check_circle,
                        color: AppColors.forest,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTypography.caption1Bold.copyWith(color: text, fontSize: 10),
      ),
    );
  }
}
