import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/widgets/custom_button.dart';

class ProfileTab extends StatelessWidget {
  final String profileName;
  final int streakCount;
  final int totalPlants;
  final VoidCallback onLogout;

  const ProfileTab({
    super.key,
    required this.profileName,
    required this.streakCount,
    required this.totalPlants,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.forest.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.forest, width: 2),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 44,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  profileName,
                  style: AppTypography.displayLarge.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 4),
                Text(
                  'Orang Tua Tanaman 🌱',
                  style: AppTypography.footnoteRegular.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  title: 'Total Tanaman',
                  value: '$totalPlants',
                  icon: Icons.local_florist_outlined,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  title: 'Streak Aktif',
                  value: '$streakCount Hari',
                  icon: Icons.local_fire_department_outlined,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Keluar (Logout)',
            isOutlined: true,
            textColor: AppColors.pastelRedText,
            height: 50,
            borderRadius: BorderRadius.circular(30),
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.largeTitleBold.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTypography.caption1Regular.copyWith(
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
