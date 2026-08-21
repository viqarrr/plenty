import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';

/// Wizard Step: Select plant growth origin (seedling vs mature plant) before environment setup.
class WizardGrowthStageStep extends StatelessWidget {
  final String selectedStage;
  final ValueChanged<String> onStageChanged;

  const WizardGrowthStageStep({
    super.key,
    required this.selectedStage,
    required this.onStageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSeed = selectedStage == 'seed';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Asal Pertumbuhan',
            style: AppTypography.title2Bold.copyWith(
              color: AppColors.inkSoft,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bagaimana kondisi tanamanmu saat pertama kali mulai dirawat?',
            style: AppTypography.bodyRegular.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 28),

          // Option 1: Dari Bibit / Benih
          _GrowthStageCard(
            title: 'Ditanam dari Bibit / Benih',
            subtitle:
                'Kamu menanam dan merawatnya dari biji, umbi, spora, atau tunas kecil sejak awal.',
            icon: Icons.spa_outlined,
            isSelected: isSeed,
            onTap: () => onStageChanged('seed'),
          ),
          const SizedBox(height: 16),

          // Option 2: Sudah Tumbuh Besar
          _GrowthStageCard(
            title: 'Sudah Tumbuh Besar',
            subtitle:
                'Tanaman hidup atau tanaman dewasa yang sudah berakar kokoh dan memiliki daun saat kamu adopsi.',
            icon: Icons.park_outlined,
            isSelected: !isSeed,
            onTap: () => onStageChanged('mature'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _GrowthStageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GrowthStageCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.pastelGreenBg.withValues(alpha: 0.6)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.forest : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.forest.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.forest
                        : AppColors.pastelGreenBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected ? Colors.white : AppColors.forest,
                  ),
                ),
                Spacer(),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected ? AppColors.forest : AppColors.muted,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTypography.calloutBold.copyWith(
                color: isSelected ? AppColors.forest : AppColors.inkSoft,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.bodyRegular.copyWith(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
