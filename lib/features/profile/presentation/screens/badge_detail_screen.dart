import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/di/injector.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/badge_ui_extension.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/features/community/domain/models/community_post.dart';
import 'package:plenty/features/community/domain/repositories/community_repository.dart';
import 'package:plenty/features/garden/presentation/screens/home_screen.dart';
import 'package:plenty/features/profile/domain/models/badge_item.dart';

/// Full-screen detail screen for a [BadgeItem].
/// Displays an illuminated vibrant experience for unlocked badges,
/// or a dark slate focused progress view for locked badges.
class BadgeDetailScreen extends StatelessWidget {
  final BadgeItem badge;
  final ICommunityRepository? communityRepository;
  final bool? isAlreadyShared;
  final void Function(BuildContext context)? onNavigateToHomeScreen;

  const BadgeDetailScreen({
    super.key,
    required this.badge,
    this.communityRepository,
    this.isAlreadyShared,
    this.onNavigateToHomeScreen,
  });

  /// Static helper to navigate to [BadgeDetailScreen].
  static Future<void> open(
    BuildContext context,
    BadgeItem badge, {
    ICommunityRepository? communityRepository,
    bool? isAlreadyShared,
    void Function(BuildContext context)? onNavigateToHomeScreen,
  }) {
    return context.push(
      BadgeDetailScreen(
        badge: badge,
        communityRepository: communityRepository,
        isAlreadyShared: isAlreadyShared,
        onNavigateToHomeScreen: onNavigateToHomeScreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (badge.isUnlocked) {
      return _UnlockedBadgeScreen(
        badge: badge,
        communityRepository: communityRepository,
        isAlreadyShared: isAlreadyShared,
        onNavigateToHomeScreen: onNavigateToHomeScreen,
      );
    }
    return _LockedBadgeScreen(badge: badge);
  }
}

/// Unlocked State: Full-screen illuminated presentation matching badge's unique theme
class _UnlockedBadgeScreen extends StatefulWidget {
  final BadgeItem badge;
  final ICommunityRepository? communityRepository;
  final bool? isAlreadyShared;
  final void Function(BuildContext context)? onNavigateToHomeScreen;

  const _UnlockedBadgeScreen({
    required this.badge,
    this.communityRepository,
    this.isAlreadyShared,
    this.onNavigateToHomeScreen,
  });

  @override
  State<_UnlockedBadgeScreen> createState() => _UnlockedBadgeScreenState();
}

class _UnlockedBadgeScreenState extends State<_UnlockedBadgeScreen> {
  late final ICommunityRepository _communityRepo;
  bool _isAlreadyShared = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _communityRepo = widget.communityRepository ?? Injector.communityRepository;
    if (widget.isAlreadyShared != null) {
      _isAlreadyShared = widget.isAlreadyShared!;
    } else {
      _checkIfAlreadyShared();
    }
  }

  Future<void> _checkIfAlreadyShared() async {
    final result = await _communityRepo.hasUserSharedBadge(widget.badge.id);
    if (mounted && result.isSuccess) {
      setState(() {
        _isAlreadyShared = result.dataOrNull ?? false;
      });
    }
  }

  List<Color> _buildBackgroundGradient(Color accent) {
    final hsl = HSLColor.fromColor(accent);
    final top = hsl
        .withLightness(0.16)
        .withSaturation((hsl.saturation * 0.9).clamp(0.25, 0.55))
        .toColor();
    final middle = hsl
        .withLightness(0.10)
        .withSaturation((hsl.saturation * 0.8).clamp(0.20, 0.45))
        .toColor();
    final bottom = hsl
        .withLightness(0.06)
        .withSaturation((hsl.saturation * 0.7).clamp(0.15, 0.35))
        .toColor();
    return [top, middle, bottom];
  }

  Color _buildButtonBg(Color accent) {
    final hsl = HSLColor.fromColor(accent);
    return hsl
        .withLightness(0.68)
        .withSaturation((hsl.saturation * 0.9).clamp(0.40, 0.75))
        .toColor();
  }

  Color _buildButtonText(Color accent) {
    final hsl = HSLColor.fromColor(accent);
    return hsl
        .withLightness(0.12)
        .withSaturation((hsl.saturation * 0.9).clamp(0.35, 0.60))
        .toColor();
  }

  Color _buildDateChipText(Color accent) {
    final hsl = HSLColor.fromColor(accent);
    return hsl
        .withLightness(0.80)
        .withSaturation((hsl.saturation * 0.85).clamp(0.35, 0.70))
        .toColor();
  }

  Future<void> _handleShareBadge() async {
    if (_isAlreadyShared || _isSharing) return;
    setState(() => _isSharing = true);

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
          'Hore! Saya baru saja membuka lencana "${widget.badge.title}" (Lv.${widget.badge.level}) di Plenty! 🌱✨',
      attachedBadge: widget.badge,
      likesCount: 0,
      isLiked: false,
      commentsCount: 0,
      createdAt: DateTime.now(),
    );

    final result = await _communityRepo.createPost(newPost);

    if (mounted) {
      setState(() {
        _isSharing = false;
        if (result.isSuccess) {
          _isAlreadyShared = true;
        }
      });

      if (result.isSuccess) {
        if (widget.onNavigateToHomeScreen != null) {
          widget.onNavigateToHomeScreen!(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lencana berhasil dibagikan ke Komunitas! 🏆'),
              backgroundColor: AppColors.darkGreen,
            ),
          );
          // Navigate to HomeScreen on Community Tab (index 2) so BottomNav remains intact
          context.pushAndRemoveAll(const HomeScreen(initialTab: 2));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.failureOrNull?.message ?? 'Gagal membagikan lencana',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _buildBackgroundGradient(widget.badge.accentColor);
    final buttonBgColor = _buildButtonBg(widget.badge.accentColor);
    final buttonTextColor = _buildButtonText(widget.badge.accentColor);
    final dateChipTextColor = _buildDateChipText(widget.badge.accentColor);

    return Scaffold(
      backgroundColor: gradientColors[1],
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
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
                              color: widget.badge.accentColor.withValues(
                                alpha: 0.40,
                              ),
                              blurRadius: 44,
                              spreadRadius: 12,
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
                          color: widget.badge.bgColor,
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
                            widget.badge.icon,
                            size: 64,
                            color: widget.badge.accentColor,
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
                            color: widget.badge.accentColor,
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
                            widget.badge.level.toString(),
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
                  widget.badge.title,
                  style: AppTypography.title2Bold.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Date unlocked chip if available
                if (widget.badge.unlockedDate != null &&
                    widget.badge.unlockedDate!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.badge.accentColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.badge.unlockedDate!,
                      style: AppTypography.caption2Bold.copyWith(
                        color: dateChipTextColor,
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
                    widget.badge.desc,
                    style: AppTypography.bodyRegular.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.5,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 36),

                // "Bagikan ke Komunitas" CTA / "Sudah Dibagikan"
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: _isAlreadyShared
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: widget.badge.accentColor.withValues(
                                alpha: 0.35,
                              ),
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 20,
                                  color: dateChipTextColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Sudah Dibagikan ke Komunitas',
                                  style: AppTypography.headlineSemiBold
                                      .copyWith(
                                        color: dateChipTextColor,
                                        fontSize: 15,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _isSharing ? null : _handleShareBadge,
                          icon: Icon(
                            _isSharing
                                ? Icons.hourglass_top_rounded
                                : Icons.share_rounded,
                            size: 20,
                            color: buttonTextColor,
                          ),
                          label: Text(
                            _isSharing
                                ? 'Membagikan...'
                                : 'Bagikan ke Komunitas',
                            style: AppTypography.headlineSemiBold.copyWith(
                              color: buttonTextColor,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonBgColor,
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
                          color: HSLColor.fromColor(
                            badge.accentColor,
                          ).withLightness(0.68).toColor(),
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
                      valueColor: AlwaysStoppedAnimation<Color>(
                        badge.accentColor,
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
