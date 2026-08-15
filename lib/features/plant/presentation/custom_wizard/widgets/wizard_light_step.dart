import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_typography.dart';

/// Step 2: Light intensity and distance from window.
class WizardLightStep extends StatelessWidget {
  final String lightIntensity;
  final String distanceFromWindow;
  final ValueChanged<String> onLightIntensityChanged;
  final ValueChanged<String> onDistanceChanged;

  const WizardLightStep({
    super.key,
    required this.lightIntensity,
    required this.distanceFromWindow,
    required this.onLightIntensityChanged,
    required this.onDistanceChanged,
  });

  static const List<String> lightIntensities = [
    'Sinar Tidak Langsung',
    'Pencahayaan rendah',
    'sinar matahari',
  ];

  static const List<String> distances = [
    'Tepat di Jendela (0-30 cm)',
    'Dekat Jendela (1-1.5 meter)',
    'Jauh dari Jendela (2 meter +)',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Intensitas Cahaya',
          style: AppTypography.headline.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 12),
        ...lightIntensities.map((light) {
          final isSelected = lightIntensity == light;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              onTap: () => onLightIntensityChanged(light),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.pastelGreenBg
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.forest : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.light_mode_outlined,
                      color: isSelected ? AppColors.forest : AppColors.muted,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      light,
                      style: AppTypography.headline.copyWith(
                        fontSize: 14,
                        color: isSelected ? AppColors.forest : AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        Text(
          'Jarak Dari Jendela',
          style: AppTypography.headline.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 12),
        ...distances.map((dist) {
          final isSelected = distanceFromWindow == dist;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              onTap: () => onDistanceChanged(dist),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.pastelGreenBg
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.forest : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  dist,
                  style: AppTypography.footnoteBold.copyWith(
                    color: isSelected ? AppColors.forest : AppColors.inkSoft,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
