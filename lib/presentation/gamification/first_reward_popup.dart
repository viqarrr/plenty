import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/widgets/custom_button.dart';

class FirstRewardPopup extends StatelessWidget {
  final String plantNickname;
  final VoidCallback onDismiss;

  const FirstRewardPopup({
    super.key,
    required this.plantNickname,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
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
                  colors: [
                    AppColors.pastelYellowBg,
                    Colors.amber.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.emoji_events, color: Colors.amber, size: 54),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Badge Pertama Terbuka! 🏆',
              textAlign: TextAlign.center,
              style: AppTypography.displayLarge.copyWith(
                fontSize: 22,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selamat! Kamu telah berhasil mengadopsi "$plantNickname" sebagai tanaman pertamamu. Terus rawat tanamanmu untuk meraih reward berikutnya!',
              textAlign: TextAlign.center,
              style: AppTypography.footnoteRegular.copyWith(
                color: AppColors.muted,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Klaim & Lanjutkan',
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
