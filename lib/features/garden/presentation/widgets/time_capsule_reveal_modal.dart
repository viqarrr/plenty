import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/features/garden/domain/models/time_capsule_model.dart';

/// Full modal celebratory dialog when a Time Capsule is unlocked and revealed.
class TimeCapsuleRevealModal extends StatelessWidget {
  final TimeCapsuleModel capsule;
  final String plantNickname;

  const TimeCapsuleRevealModal({
    super.key,
    required this.capsule,
    required this.plantNickname,
  });

  String _formatDate(DateTime dt) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.canvasDefault,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.pastelGreenBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.forest, width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock_open,
                    color: AppColors.forest,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Kapsul Waktu Terbuka! 🎉',
              textAlign: TextAlign.center,
              style: AppTypography.displayLarge.copyWith(
                fontSize: 22,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pesan dari masa lalu untuk $plantNickname',
              textAlign: TextAlign.center,
              style: AppTypography.footnoteRegular.copyWith(
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ditulis:',
                        style: AppTypography.caption1Regular.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                      Text(
                        _formatDate(capsule.createdAt),
                        style: AppTypography.caption1Bold.copyWith(
                          color: AppColors.forest,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Text(
                    '"${capsule.message}"',
                    style: AppTypography.bodyRegular.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.inkSoft,
                      height: 1.5,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Tutup & Simpan Kenangan',
              height: 48,
              borderRadius: BorderRadius.circular(24),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
