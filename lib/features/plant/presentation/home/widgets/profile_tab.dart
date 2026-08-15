import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_typography.dart';
import 'package:plenty/core/utils/widgets/widgets.dart';

/// Profile screen tab showing care achievements and logout action.
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
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.pastelGreenBg,
            child: Icon(Icons.person, size: 48, color: AppColors.forest),
          ),
          const SizedBox(height: 16),
          Text(
            profileName,
            style: AppTypography.title2Bold.copyWith(
              color: AppColors.inkSoft,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Plant Enthusiast',
            style: AppTypography.footnoteRegular.copyWith(
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 24),
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard('🔥 Streak', '$streakCount Hari'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('🌿 Koleksi', '$totalPlants Tanaman'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Keluar',
            isOutlined: true,
            textColor: AppColors.error,
            icon: Icons.logout,
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.headline.copyWith(
              color: AppColors.forest,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.caption1Regular.copyWith(
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Akun'),
        content: const Text('Apakah kamu yakin ingin keluar dari Plenty?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onLogout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
