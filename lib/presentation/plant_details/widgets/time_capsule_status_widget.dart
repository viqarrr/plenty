import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/data/models/time_capsule_model.dart';
import 'package:plenty/presentation/plant_details/widgets/time_capsule_reveal_modal.dart';

/// Interactive Time Capsule card component showing empty, locked, or unlocked status.
class TimeCapsuleStatusWidget extends StatelessWidget {
  final TimeCapsuleModel? capsule;
  final String plantNickname;
  final VoidCallback onCreatePressed;

  const TimeCapsuleStatusWidget({
    super.key,
    required this.capsule,
    required this.plantNickname,
    required this.onCreatePressed,
  });

  @override
  Widget build(BuildContext context) {
    if (capsule == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.lock_clock, size: 36, color: AppColors.muted),
            const SizedBox(height: 8),
            Text(
              'Belum ada Kapsul Waktu untuk tanaman ini.',
              style: AppTypography.footnoteRegular.copyWith(
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Buat Kapsul Waktu',
              height: 42,
              borderRadius: BorderRadius.circular(20),
              onPressed: onCreatePressed,
            ),
          ],
        ),
      );
    }

    final isUnlocked =
        capsule!.isUnlocked || DateTime.now().isAfter(capsule!.unlockAt);

    if (!isUnlocked) {
      final daysRemaining =
          capsule!.unlockAt.difference(DateTime.now()).inDays;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.pastelYellowBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.pastelYellowText.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lock,
              color: AppColors.pastelYellowText,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time Capsule Terkunci ⏳',
                    style: AppTypography.calloutBold.copyWith(
                      color: AppColors.pastelYellowText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dapat dibuka dalam $daysRemaining hari lagi.',
                    style: AppTypography.footnoteRegular.copyWith(
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => TimeCapsuleRevealModal(
            capsule: capsule!,
            plantNickname: plantNickname,
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.pastelGreenBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.forest),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_open, color: AppColors.forest, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Kapsul Waktu Terbuka! 🎉',
                  style: AppTypography.calloutBold.copyWith(
                    color: AppColors.forest,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.forest,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '"${capsule!.message}"',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyRegular.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
