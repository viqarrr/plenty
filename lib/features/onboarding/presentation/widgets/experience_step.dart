import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';

/// Step 1 widget of Preferences Flow: Plant experience selection.
class ExperienceStep extends StatelessWidget {
  final String selectedExperience;
  final ValueChanged<String> onSelected;

  const ExperienceStep({
    super.key,
    required this.selectedExperience,
    required this.onSelected,
  });

  static const List<Map<String, String>> experiences = [
    {'title': 'Pemula', 'desc': 'Belum pernah merawat tanaman.'},
    {'title': 'Penggemar', 'desc': 'Pernah merawat tanaman hias.'},
    {'title': 'Mahir', 'desc': 'Aku adalah tanaman dan tanaman adalah aku.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seberapa jauh pengalaman merawat tanamanmu?',
          style: AppTypography.title2Bold.copyWith(
            color: AppColors.ink,
            fontSize: 36,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pilih satu yang paling sesuai untuk membantu menyesuaikan panduan perawatan.',
          style: AppTypography.bodyRegular.copyWith(
            color: AppColors.muted,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 32),
        ...experiences.map((exp) {
          final title = exp['title'] ?? '';
          final desc = exp['desc'] ?? '';
          final isSelected = selectedExperience == title;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: InkWell(
              onTap: () => onSelected(title),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.pastelGreenBg
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.forest : AppColors.surface,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.headline.copyWith(
                              color: isSelected
                                  ? AppColors.forest
                                  : AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            style: AppTypography.footnoteRegular.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: isSelected ? AppColors.forest : AppColors.muted,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
