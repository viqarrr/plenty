import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/di/injector.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/features/profile/domain/models/badge_item.dart';
import 'package:plenty/features/profile/domain/repositories/badge_repository.dart';
import 'package:plenty/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:plenty/features/profile/presentation/widgets/activity_summary_grid.dart';
import 'package:plenty/features/profile/presentation/widgets/badge_highlight_section.dart';
import 'package:plenty/features/profile/presentation/widgets/current_progress_card.dart';
import 'package:plenty/features/profile/presentation/widgets/profile_header.dart';

/// Modern, borderless profile & gamification tab with a full-width
/// curved header, progress cards, badge highlights, and activity summaries.
class ProfileTab extends StatefulWidget {
  final String profileName;
  final String username;
  final String email;
  final String? avatarPath;
  final String? bio;
  final int streakCount;
  final int totalPlants;
  final int totalXp;
  final int userLevel;
  final int badgeCount;
  final List<BadgeItem>? badges;
  final IBadgeRepository? badgeRepository;
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
    this.badges,
    this.badgeRepository,
    this.onProfileUpdated,
    required this.onLogout,
    required this.email,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late final IBadgeRepository _badgeRepository;
  List<BadgeItem> _badges = const [];

  @override
  void initState() {
    super.initState();
    _badgeRepository = widget.badgeRepository ?? Injector.badgeRepository;
    if (widget.badges != null) {
      _badges = widget.badges!;
    } else {
      _loadBadges();
    }
  }

  @override
  void didUpdateWidget(covariant ProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.badges != null) {
      _badges = widget.badges!;
    } else {
      _loadBadges();
    }
  }

  Future<void> _loadBadges() async {
    final result = await _badgeRepository.getBadges();
    if (mounted && result.isSuccess) {
      setState(() {
        _badges = result.dataOrNull ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBadgeCount = widget.badgeCount > 0
        ? widget.badgeCount
        : _badges.where((b) => b.isUnlocked).length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Full-Width Curved Forest Header (Avatar from DB) ──
          ProfileHeader(
            profileName: widget.profileName,
            username: widget.username,
            avatarPath: widget.avatarPath,
            onSettingsTap: () async {
              await context.push(
                ProfileEditScreen(
                  onLogout: widget.onLogout,
                  initialDisplayName: widget.profileName,
                  initialUsername: widget.username,
                  initialEmail: widget.email,
                  initialBio:
                      widget.bio ?? 'Urban gardener berlokasi di Jakarta...',
                  initialAvatarPath: widget.avatarPath,
                ),
              );
              _loadBadges();
              widget.onProfileUpdated?.call();
            },
          ),

          // ── Padded Gamification & Progress Cards ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Current Progress & XP Card ──
                CurrentProgressCard(
                  userLevel: widget.userLevel,
                  totalXp: widget.totalXp,
                ),

                const SizedBox(height: 24),

                // ── 2. Badge Highlight Section (Horizontal Carousel) ──
                BadgeHighlightSection(
                  badges: _badges,
                  badgeRepository: _badgeRepository,
                ),

                const SizedBox(height: 24),

                // ── 3. Section Title for Activity Overview ──
                Text(
                  'RINGKASAN AKTIVITAS',
                  style: AppTypography.caption2Bold.copyWith(
                    color: AppColors.muted,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 12),

                // ── 4. 2x2 Activity Overview Grid ──
                ActivitySummaryGrid(
                  streakCount: widget.streakCount,
                  totalPlants: widget.totalPlants,
                  badgeCount: effectiveBadgeCount,
                  totalXp: widget.totalXp,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
