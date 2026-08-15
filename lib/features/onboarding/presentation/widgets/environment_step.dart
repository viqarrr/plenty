import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_typography.dart';

/// Step 3 widget of Preferences Flow: Pets and Kids environmental toggles.
class EnvironmentStep extends StatelessWidget {
  final bool hasPets;
  final bool hasKids;
  final ValueChanged<bool> onPetsChanged;
  final ValueChanged<bool> onKidsChanged;

  const EnvironmentStep({
    super.key,
    required this.hasPets,
    required this.hasKids,
    required this.onPetsChanged,
    required this.onKidsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Siapa saja yang ada di rumahmu?',
          style: AppTypography.title2Bold.copyWith(
            color: AppColors.ink,
            fontSize: 36,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Aktifkan opsi yang sesuai untuk menyaring tanaman beracun.',
          style: AppTypography.bodyRegular.copyWith(
            color: AppColors.muted,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 32),
        // Pets Row
        _buildEnvironmentCard(
          icon: Icons.pets,
          iconBgColor: AppColors.pastelYellowBg,
          iconColor: AppColors.pastelYellowText,
          title: 'Hewan Peliharaan',
          subtitle: 'Kucing atau anjing.',
          value: hasPets,
          onChanged: onPetsChanged,
        ),
        const SizedBox(height: 16),
        // Kids Row
        _buildEnvironmentCard(
          icon: Icons.child_care,
          iconBgColor: AppColors.pastelBlueBg,
          iconColor: AppColors.pastelBlueText,
          title: 'Anak Kecil',
          subtitle: 'Balita atau bayi.',
          value: hasKids,
          onChanged: onKidsChanged,
        ),
      ],
    );
  }

  Widget _buildEnvironmentCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.headline),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.footnoteRegular.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.forest,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
