import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/badge_ui_extension.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/features/profile/domain/models/badge_item.dart';

/// Reusable popup modal displaying newly unlocked badges and achievements.
class RewardPopup extends StatelessWidget {
  final String? title;
  final String? message;
  final String? plantNickname;
  final IconData? icon;
  final Color? iconColor;
  final List<Color>? gradientColors;
  final String buttonText;
  final VoidCallback onDismiss;
  final BadgeItem? badge;

  const RewardPopup({
    super.key,
    this.title,
    this.message,
    this.plantNickname,
    this.icon,
    this.iconColor,
    this.gradientColors,
    this.buttonText = 'Klaim & Lanjutkan',
    required this.onDismiss,
    this.badge,
  });

  /// Factory constructor for First Plant Adoption badge.
  factory RewardPopup.firstPlant({
    Key? key,
    required String plantNickname,
    required VoidCallback onDismiss,
    String buttonText = 'Klaim & Lanjutkan',
  }) => RewardPopup(
    key: key,
    title: 'Badge Pertama Terbuka! 🏆',
    message:
        'Selamat! Kamu telah berhasil mengadopsi "$plantNickname" sebagai tanaman pertamamu. Terus rawat tanamanmu untuk meraih reward berikutnya!',
    plantNickname: plantNickname,
    icon: Icons.emoji_events_rounded,
    iconColor: Colors.amber.shade700,
    gradientColors: const [AppColors.pastelYellowBg, Color(0xFFFFE082)],
    buttonText: buttonText,
    onDismiss: onDismiss,
  );

  /// Factory constructor for First Time Capsule badge.
  factory RewardPopup.timeCapsule({
    Key? key,
    String? plantNickname,
    required VoidCallback onDismiss,
    String buttonText = 'Klaim & Lanjutkan',
  }) => RewardPopup(
    key: key,
    title: 'Kapsul Waktu Terbuka! ⏳',
    message: plantNickname != null && plantNickname.isNotEmpty
        ? 'Selamat! Kamu telah berhasil membuat pesan Kapsul Waktu pertamamu untuk "$plantNickname". Pesan ini akan terkunci aman hingga saatnya dibuka nanti!'
        : 'Selamat! Kamu telah berhasil membuat pesan Kapsul Waktu pertamamu. Pesan ini akan terkunci aman hingga saatnya dibuka nanti!',
    plantNickname: plantNickname,
    icon: Icons.hourglass_top_rounded,
    iconColor: const Color(0xFF1F6C9F),
    gradientColors: const [Color(0xFFE3F0FF), Color(0xFFBAD8F7)],
    buttonText: buttonText,
    onDismiss: onDismiss,
  );

  /// Factory constructor from a generic BadgeItem domain model.
  factory RewardPopup.fromBadge({
    Key? key,
    required BadgeItem badge,
    String? plantNickname,
    required VoidCallback onDismiss,
    String buttonText = 'Klaim & Lanjutkan',
  }) => RewardPopup(
    key: key,
    badge: badge,
    title: '${badge.title} Terbuka! 🏆',
    message: badge.desc.isNotEmpty
        ? badge.desc
        : 'Selamat! Kamu telah berhasil membuka badge baru.',
    plantNickname: plantNickname,
    icon: badge.icon,
    iconColor: badge.accentColor,
    gradientColors: [badge.bgColor, badge.accentColor.withValues(alpha: 0.25)],
    buttonText: buttonText,
    onDismiss: onDismiss,
  );

  @override
  Widget build(BuildContext context) {
    final effectiveTitle =
        title ??
        (badge != null
            ? '${badge!.title} Terbuka! 🏆'
            : 'Badge Pertama Terbuka! 🏆');

    final effectiveMessage =
        message ??
        (plantNickname != null
            ? 'Selamat! Kamu telah berhasil mengadopsi "$plantNickname" sebagai tanaman pertamamu. Terus rawat tanamanmu untuk meraih reward berikutnya!'
            : (badge?.desc.isNotEmpty == true
                  ? badge!.desc
                  : 'Selamat! Kamu telah berhasil membuka badge baru.'));

    final effectiveIcon = icon ?? badge?.icon ?? Icons.emoji_events_rounded;
    final effectiveIconColor =
        iconColor ?? badge?.accentColor ?? Colors.amber.shade700;

    final effectiveGradient =
        gradientColors ??
        (badge != null
            ? [badge!.bgColor, badge!.accentColor.withValues(alpha: 0.25)]
            : [AppColors.pastelYellowBg, Colors.amber.withValues(alpha: 0.3)]);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: effectiveGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: effectiveIconColor.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Icon(effectiveIcon, color: effectiveIconColor, size: 52),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              effectiveTitle,
              textAlign: TextAlign.center,
              style: AppTypography.displayLarge.copyWith(
                fontSize: 22,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              effectiveMessage,
              textAlign: TextAlign.center,
              style: AppTypography.footnoteRegular.copyWith(
                color: AppColors.muted,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: buttonText,
              height: 48,
              borderRadius: BorderRadius.circular(24),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

/// Semantic alias for FirstRewardPopup.
typedef RewardBadgePopup = RewardPopup;
