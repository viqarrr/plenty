import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/di/injector.dart';
import 'package:plenty/core/domain/models/badge_item.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/badge_ui_extension.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/features/profile/domain/repositories/badge_repository.dart';
import 'package:plenty/features/profile/presentation/screens/badge_detail_screen.dart';

/// Screen displaying all achievement badges in a 3-column grid,
/// with unlocked status, progress, and full-screen detail screen on tap.
class AllBadgesScreen extends StatefulWidget {
  final List<BadgeItem>? badges;
  final IBadgeRepository? badgeRepository;

  const AllBadgesScreen({
    super.key,
    this.badges,
    this.badgeRepository,
  });

  @override
  State<AllBadgesScreen> createState() => _AllBadgesScreenState();
}

class _AllBadgesScreenState extends State<AllBadgesScreen> {
  late final IBadgeRepository _repository;
  List<BadgeItem> _badges = const [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.badgeRepository ?? Injector.badgeRepository;
    if (widget.badges != null && widget.badges!.isNotEmpty) {
      _badges = widget.badges!;
    } else {
      _loadBadges();
    }
  }

  Future<void> _loadBadges() async {
    setState(() => _isLoading = true);
    final result = await _repository.getBadges();
    if (mounted) {
      switch (result) {
        case Success(:final data):
          setState(() {
            _badges = data;
            _isLoading = false;
          });
        case Error():
          setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlockedCount = _badges.where((b) => b.isUnlocked).length;
    final totalCount = _badges.length;

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        backgroundColor: AppColors.canvasBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppColors.inkDark,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Pencapaian',
          style: AppTypography.headline.copyWith(
            color: AppColors.inkDark,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.forest,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header: Title and Count Chip ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SEMUA PENGHARGAAN',
                        style: AppTypography.caption2Bold.copyWith(
                          color: AppColors.muted,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.pastelGreenBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unlockedCount/$totalCount Terbuka',
                          style: AppTypography.caption1Bold.copyWith(
                            color: AppColors.pastelGreenText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── 3-Column Badges GridView ──
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _badges.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.76,
                    ),
                    itemBuilder: (context, index) {
                      final badge = _badges[index];
                      return _BadgeGridTile(badge: badge);
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

/// Single Badge Tile in the 3-column GridView
class _BadgeGridTile extends StatelessWidget {
  final BadgeItem badge;

  const _BadgeGridTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => BadgeDetailScreen.open(context, badge),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: badge.isUnlocked
                ? badge.accentColor.withValues(alpha: 0.2)
                : AppColors.border.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 60x60 Circular Badge Icon
            _BadgeIconWithPill(badge: badge),
            const SizedBox(height: 8),

            // Badge Title
            Text(
              badge.title,
              style: AppTypography.caption1Bold.copyWith(
                color: badge.isUnlocked ? AppColors.inkDark : AppColors.muted,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Status or Progress Subtitle
            Text(
              badge.isUnlocked
                  ? (badge.unlockedDate ?? 'Terbuka')
                  : '${badge.progress}/${badge.total}',
              style: AppTypography.caption2Regular.copyWith(
                color: badge.isUnlocked
                    ? AppColors.pastelGreenText
                    : AppColors.muted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 60x60 Circular Badge Container with Level Pill Badge
class _BadgeIconWithPill extends StatelessWidget {
  final BadgeItem badge;

  const _BadgeIconWithPill({required this.badge});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Circular container
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badge.isUnlocked ? badge.bgColor : const Color(0xFFF1F3F5),
              border: Border.all(
                color: badge.isUnlocked
                    ? badge.accentColor.withValues(alpha: 0.4)
                    : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                badge.icon,
                size: 26,
                color: badge.isUnlocked ? badge.accentColor : AppColors.muted,
              ),
            ),
          ),

          // Level Pill Tag
          Positioned(
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: badge.isUnlocked
                    ? badge.accentColor
                    : const Color(0xFFADB5BD),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              child: Text(
                badge.level.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
