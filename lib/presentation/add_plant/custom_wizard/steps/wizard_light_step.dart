import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';

/// Step 4: Sunlight condition selection with descriptive helper text & icons.
class WizardLightStep extends StatelessWidget {
  final String selectedLight;
  final ValueChanged<String> onLightSelected;

  const WizardLightStep({
    super.key,
    required this.selectedLight,
    required this.onLightSelected,
  });

  static const List<Map<String, dynamic>> _lightLevels = [
    {
      'title': 'Sinar Tidak Langsung Terang',
      'icon': Icons.wb_sunny_outlined,
      'color': Colors.orange,
      'desc': 'Cahaya terang tersaring gorden/jendela tanpa terkena sinar terik langsung.',
    },
    {
      'title': 'Sinar Langsung Penuh (Full Sun)',
      'icon': Icons.light_mode,
      'color': Colors.amber,
      'desc': 'Terkena sinar matahari langsung minimal 4-6 jam sehari (balkon/teras).',
    },
    {
      'title': 'Teduh Sebagian (Partial Shade)',
      'icon': Icons.cloud_outlined,
      'color': Colors.blueGrey,
      'desc': 'Mendapatkan sinar pagi yang lembut atau cahaya tidak langsung sedang.',
    },
    {
      'title': 'Pencahayaan Rendah (Low Light)',
      'icon': Icons.nightlight_round_outlined,
      'color': Colors.indigo,
      'desc': 'Jauh dari jendela atau hanya mengandalkan lampu ruangan dalam.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kondisi Pencahayaan',
            style: AppTypography.displayLarge.copyWith(
              fontSize: 22,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Berapa banyak intensitas cahaya yang diterima tanaman di posisi ini?',
            style: AppTypography.bodyRegular.copyWith(
              color: AppColors.muted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),

          // Light Level Options
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _lightLevels.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final light = _lightLevels[index];
              final title = light['title'] as String;
              final icon = light['icon'] as IconData;
              final iconColor = light['color'] as Color;
              final desc = light['desc'] as String;
              final isSelected = selectedLight == title;

              return GestureDetector(
                onTap: () => onLightSelected(title),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.pastelGreenBg
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.forest : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.forest
                              : iconColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? Colors.white : iconColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTypography.calloutBold.copyWith(
                                color: isSelected
                                    ? AppColors.forest
                                    : AppColors.inkSoft,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              desc,
                              style: AppTypography.footnoteRegular.copyWith(
                                color: AppColors.muted,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected ? AppColors.forest : AppColors.muted,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
