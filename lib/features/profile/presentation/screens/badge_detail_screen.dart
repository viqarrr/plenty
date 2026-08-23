import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/di/injector.dart';
import 'package:plenty/core/domain/models/badge_item.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/badge_ui_extension.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/features/community/domain/models/community_post.dart';
import 'package:plenty/features/community/domain/repositories/community_repository.dart';
import 'package:plenty/features/community/presentation/screens/community_screen.dart';

/// Full-screen detail screen for a [BadgeItem].
/// Displays an illuminated vibrant experience for unlocked badges,
/// or a dark slate focused progress view for locked badges.
class BadgeDetailScreen extends StatelessWidget {
  final BadgeItem badge;
  final ICommunityRepository? communityRepository;

  const BadgeDetailScreen({
    super.key,
    required this.badge,
    this.communityRepository,
  });

  /// Static helper to navigate to [BadgeDetailScreen].
  static Future<void> open(
    BuildContext context,
    BadgeItem badge, {
    ICommunityRepository? communityRepository,
  }) {
    return context.push(
      BadgeDetailScreen(
        badge: badge,
        communityRepository: communityRepository,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (badge.isUnlocked) {
      return _UnlockedBadgeScreen(
        badge: badge,
        communityRepository: communityRepository,
      );
    }
    return _LockedBadgeScreen(badge: badge);
  }
}

/// Unlocked State: Full-screen illuminated botanical presentation
class _UnlockedBadgeScreen extends StatelessWidget {
  final BadgeItem badge;
  final ICommunityRepository? communityRepository;

  const _UnlockedBadgeScreen({required this.badge, this.communityRepository});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF132A1F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B3D2D), Color(0xFF132A1F), Color(0xFF0D1E16)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF52B788,
                              ).withValues(alpha: 0.35),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      // Badge circular surface
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: badge.bgColor,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            badge.icon,
                            size: 64,
                            color: badge.accentColor,
                          ),
                        ),
                      ),
                      // Level chip at bottom
                      Positioned(
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D6A4F),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            badge.level.toString(),
                            style: AppTypography.caption1Bold.copyWith(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Badge Title
                Text(
                  badge.title,
                  style: AppTypography.title2Bold.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Date unlocked chip if available
                if (badge.unlockedDate != null &&
                    badge.unlockedDate!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge.unlockedDate!,
                      style: AppTypography.caption2Bold.copyWith(
                        color: const Color(0xFFB7E4C7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Description card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    badge.desc,
                    style: AppTypography.bodyRegular.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.5,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 36),

                // "Bagikan ke Komunitas" CTA
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      String author = 'Penggemar Tanaman';
                      String? avatar;
                      try {
                        final currentUser = await PreferenceHandler.getUser();
                        if (currentUser != null) {
                          if (currentUser.username.isNotEmpty) {
                            author = currentUser.username;
                          } else if (currentUser.displayName.isNotEmpty) {
                            author = currentUser.displayName;
                          }
                          avatar = currentUser.avatarUrl;
                        }
                      } catch (_) {}

                      final newPost = CommunityPost(
                        id: 'cp_${DateTime.now().millisecondsSinceEpoch}',
                        authorName: author,
                        authorAvatar: avatar,
                        timeAgo: 'Baru saja',
                        category: 'pencapaian',
                        content:
                            'Hore! Saya baru saja membuka lencana "${badge.title}" (Lv.${badge.level}) di Plenty! 🌱✨',
                        attachedBadge: badge,
                        likesCount: 0,
                        isLiked: false,
                        commentsCount: 0,
                        createdAt: DateTime.now(),
                      );
                      final repo = communityRepository ?? Injector.communityRepository;
                      await repo.createPost(newPost);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Lencana berhasil dibagikan ke Komunitas! 🏆',
                            ),
                            backgroundColor: AppColors.darkGreen,
                          ),
                        );
                        context.pushReplacement(
                          const CommunityScreen(
                            initialCategory: 'pencapaian',
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.share_rounded,
                      size: 20,
                      color: Color(0xFF132A1F),
                    ),
                    label: Text(
                      'Bagikan ke Komunitas',
                      style: AppTypography.headlineSemiBold.copyWith(
                        color: const Color(0xFF132A1F),
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF74C69D),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Locked State: Full-screen dark slate focused progress view
class _LockedBadgeScreen extends StatelessWidget {
  final BadgeItem badge;

  const _LockedBadgeScreen({required this.badge});

  @override
  Widget build(BuildContext context) {
    final progressFraction = badge.total > 0
        ? (badge.progress / badge.total).clamp(0.0, 1.0)
        : 0.0;
    final progressPct = (progressFraction * 100).toInt();

    return Scaffold(
      backgroundColor: const Color(0xFF14171A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Locked badge silhouette
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1E2328),
                      border: Border.all(
                        color: const Color(0xFF2C3238),
                        width: 2.5,
                      ),
                    ),
                    child: Center(
                      child: Opacity(
                        opacity: 0.22,
                        child: Icon(badge.icon, size: 64, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C3238),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF4A525A),
                          width: 1.2,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            size: 12,
                            color: Color(0xFF9AA5B1),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Terkunci',
                            style: TextStyle(
                              color: Color(0xFF9AA5B1),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Badge Title
            Text(
              badge.title,
              style: AppTypography.title2Bold.copyWith(
                color: Colors.white,
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Narrative criteria
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Text(
                badge.desc,
                style: AppTypography.bodyRegular.copyWith(
                  color: const Color(0xFFCBD2D9),
                  height: 1.5,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 28),

            // Progress Section Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2328),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF2C3238)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progres Pencapaian',
                        style: AppTypography.bodyBold.copyWith(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${badge.progress} / ${badge.total} ($progressPct%)',
                        style: AppTypography.caption1Bold.copyWith(
                          color: const Color(0xFF52B788),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progressFraction,
                      minHeight: 10,
                      backgroundColor: const Color(0xFF2C3238),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF52B788),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}
