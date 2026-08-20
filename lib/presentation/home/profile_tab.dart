import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/presentation/home/profile/activity_summary_grid.dart';
import 'package:plenty/presentation/home/profile/current_progress_card.dart';
import 'package:plenty/presentation/home/profile/profile_header.dart';
import 'package:plenty/presentation/profile/profile_edit_screen.dart';

/// Modern, borderless profile & gamification tab with a full-width
/// curved header and padded activity & progress cards.
class ProfileTab extends StatelessWidget {
  final String profileName;
  final String username;
  final String? avatarPath;
  final String? bio;
  final int streakCount;
  final int totalPlants;
  final int totalXp;
  final int userLevel;
  final int badgeCount;
  final VoidCallback? onProfileUpdated;
  final VoidCallback onLogout;

  const ProfileTab({
    super.key,
    required this.profileName,
    this.username = 'alex_plants',
    this.avatarPath,
    this.bio,
    required this.streakCount,
    required this.totalPlants,
    this.totalXp = 0,
    this.userLevel = 1,
    this.badgeCount = 0,
    this.onProfileUpdated,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Full-Width Curved Forest Header (Avatar from DB) ──
          ProfileHeader(
            profileName: profileName,
            username: username,
            avatarPath: avatarPath,
            onSettingsTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ProfileEditScreen(
                    onLogout: onLogout,
                    initialDisplayName: profileName,
                    initialUsername: username,
                    initialBio: bio ?? 'Urban gardener berlokasi di Jakarta...',
                    initialAvatarPath: avatarPath,
                  ),
                ),
              );
              onProfileUpdated?.call();
            },
          ),
          const SizedBox(height: 20),

          // ── Padded Gamification & Progress Cards ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Current Progress (Real Level & XP) ──
                CurrentProgressCard(
                  userLevel: userLevel,
                  totalXp: totalXp,
                ),
                const SizedBox(height: 24),

                // ── Activity Summary (Real Streak, XP, Plants, Badges) ──
                Text(
                  'RINGKASAN AKTIVITAS',
                  style: AppTypography.caption2Bold.copyWith(
                    color: AppColors.muted,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                ActivitySummaryGrid(
                  streakCount: streakCount,
                  totalPlants: totalPlants,
                  totalXp: totalXp,
                  badgeCount: badgeCount,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
