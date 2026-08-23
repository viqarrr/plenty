import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/domain/models/badge_item.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/badge_ui_extension.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/features/profile/domain/repositories/badge_repository.dart';
import 'package:plenty/features/profile/presentation/screens/all_badges_screen.dart';
import 'package:plenty/features/profile/presentation/screens/badge_detail_screen.dart';

/// "REKOR PERSONAL" horizontal highlight list displaying up to 4 achievement badges
/// with circular icons, level pills, and full-screen detail screen interaction.
class BadgeHighlightSection extends StatelessWidget {
  final List<BadgeItem> badges;
  final IBadgeRepository? badgeRepository;

  const BadgeHighlightSection({
    super.key,
    required this.badges,
    this.badgeRepository,
  });

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayBadges = badges.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header: "REKOR PERSONAL" & "Lihat Semua" CTA ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PENCAPAIAN',
              style: AppTypography.caption2Bold.copyWith(
                color: AppColors.muted,
                letterSpacing: 1.2,
              ),
            ),
            GestureDetector(
              onTap: () {
                context.push(
                  AllBadgesScreen(
                    badges: badges,
                    badgeRepository: badgeRepository,
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat Semua',
                    style: AppTypography.caption1Bold.copyWith(
                      color: AppColors.forest,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppColors.forest,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Horizontal Badges List (Max 4 items) ──
        SizedBox(
          height: 110,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: displayBadges.map((badge) {
              return _HighlightBadgeTile(badge: badge);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Individual Badge Tile inside the horizontal highlight section
class _HighlightBadgeTile extends StatelessWidget {
  final BadgeItem badge;

  const _HighlightBadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => BadgeDetailScreen.open(context, badge),
      child: Container(
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 52x52 circular icon with level badge pill
            _HighlightBadgeIcon(badge: badge),
            const SizedBox(height: 6),

            // Badge Title
            Text(
              badge.title,
              style: AppTypography.caption1Bold.copyWith(
                fontSize: 10.5,
                color: badge.isUnlocked ? AppColors.inkDark : AppColors.muted,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // Status / Progress Caption
            Text(
              badge.isUnlocked ? 'Terbuka' : '${badge.progress}/${badge.total}',
              style: AppTypography.caption2Bold.copyWith(
                fontSize: 9,
                color: badge.isUnlocked
                    ? badge.accentColor
                    : AppColors.mutedGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// 52x52 circular badge icon with bottom-right level badge pill
class _HighlightBadgeIcon extends StatelessWidget {
  final BadgeItem badge;

  const _HighlightBadgeIcon({required this.badge});

  @override
  Widget build(BuildContext context) {
    if (badge.isUnlocked) {
      return SizedBox(
        width: 52,
        height: 52,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badge.bgColor,
                border: Border.all(
                  color: badge.accentColor.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(badge.icon, color: badge.accentColor, size: 24),
              ),
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: badge.accentColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
                child: Text(
                  'Lv.${badge.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Locked State: 0.25 opacity silhouette
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.canvasDefault,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Center(
              child: Opacity(
                opacity: 0.25,
                child: Icon(badge.icon, color: AppColors.inkDark, size: 24),
              ),
            ),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mutedGray,
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 8,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
