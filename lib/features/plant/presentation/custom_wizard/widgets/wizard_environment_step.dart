import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_typography.dart';

/// Step 1: Environment (Indoor/Outdoor) & Drainage details.
class WizardEnvironmentStep extends StatelessWidget {
  final String environment;
  final String drainage;
  final ValueChanged<String> onEnvironmentChanged;
  final ValueChanged<String> onDrainageChanged;

  const WizardEnvironmentStep({
    super.key,
    required this.environment,
    required this.drainage,
    required this.onEnvironmentChanged,
    required this.onDrainageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lingkungan',
          style: AppTypography.headline.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildChoiceCard(
                'Indoor',
                Icons.home_filled,
                environment == 'Indoor',
                () => onEnvironmentChanged('Indoor'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChoiceCard(
                'Outdoor',
                Icons.wb_cloudy_rounded,
                environment == 'Outdoor',
                () => onEnvironmentChanged('Outdoor'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'Detail Wadah',
          style: AppTypography.headline.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 12),
        _buildRadioRow(
          'Ada Lubang Drainase',
          'Di dalam ruangan menggunakan pot.',
          drainage == 'Ada Lubang Drainase',
          () => onDrainageChanged('Ada Lubang Drainase'),
        ),
        const SizedBox(height: 12),
        _buildRadioRow(
          'Tanpa Lubang Drainase',
          'Di luar ruangan menggunakan pot.',
          drainage == 'Tanpa Lubang Drainase',
          () => onDrainageChanged('Tanpa Lubang Drainase'),
        ),
      ],
    );
  }

  Widget _buildChoiceCard(
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.pastelGreenBg : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.forest : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.forest : AppColors.muted,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTypography.headline.copyWith(
                color: isSelected ? AppColors.forest : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioRow(
    String title,
    String subtitle,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.pastelGreenBg : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.forest : AppColors.border,
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
                      fontSize: 14,
                      color: isSelected ? AppColors.forest : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption1Regular.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected ? AppColors.forest : AppColors.muted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
