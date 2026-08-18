import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/widgets/custom_text_field.dart';
import 'package:plenty/data/models/time_capsule_model.dart';
import 'package:plenty/presentation/add_plant/time_capsule_modal.dart';

class NicknameHeightStep extends StatelessWidget {
  final TextEditingController nicknameController;
  final double currentHeightCm;
  final ValueChanged<double> onHeightChanged;
  final TimeCapsuleDraft? timeCapsuleDraft;
  final ValueChanged<TimeCapsuleDraft?> onTimeCapsuleChanged;

  const NicknameHeightStep({
    super.key,
    required this.nicknameController,
    required this.currentHeightCm,
    required this.onHeightChanged,
    required this.timeCapsuleDraft,
    required this.onTimeCapsuleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nama Panggilan & Ukuran',
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.inkSoft,
              fontSize: 26,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Beri nama kesayangan dan catat tinggi awal tanamanmu.',
            style: AppTypography.bodyRegular.copyWith(
              color: AppColors.muted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          CustomTextField(
            controller: nicknameController,
            label: 'Nama Panggilan Tanaman',
            hintText: 'e.g. Monty si Monstera',
            prefixIcon: const Icon(
              Icons.drive_file_rename_outline,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tinggi Awal Tanaman',
                style: AppTypography.title2Bold.copyWith(fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.pastelGreenBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${currentHeightCm.toStringAsFixed(1)} cm',
                  style: AppTypography.footnoteBold.copyWith(
                    color: AppColors.forest,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.forest,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.forest,
              overlayColor: AppColors.forest.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: currentHeightCm,
              min: 5.0,
              max: 200.0,
              divisions: 195,
              onChanged: onHeightChanged,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Kapsul Waktu (Opsional)',
            style: AppTypography.title2Bold.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Simpan pesan atau harapan untuk dibuka kembali setelah tanamanmu tumbuh selama periode tertentu.',
            style: AppTypography.footnoteRegular.copyWith(
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final result = await showModalBottomSheet<TimeCapsuleDraft?>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) =>
                    TimeCapsuleModal(initialDraft: timeCapsuleDraft),
              );
              if (result != null) {
                onTimeCapsuleChanged(result);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: timeCapsuleDraft != null
                    ? AppColors.pastelYellowBg
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: timeCapsuleDraft != null
                      ? AppColors.pastelYellowText.withValues(alpha: 0.5)
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    timeCapsuleDraft != null
                        ? Icons.lock_clock
                        : Icons.lock_outline,
                    color: timeCapsuleDraft != null
                        ? AppColors.pastelYellowText
                        : AppColors.forest,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timeCapsuleDraft != null
                              ? 'Kapsul Waktu Aktif (${timeCapsuleDraft!.durationMonths} Bulan)'
                              : 'Tambahkan Pesan Kapsul Waktu',
                          style: AppTypography.calloutBold.copyWith(
                            color: timeCapsuleDraft != null
                                ? AppColors.pastelYellowText
                                : AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeCapsuleDraft != null
                              ? '"${timeCapsuleDraft!.message}"'
                              : 'Buka di masa depan saat tanaman bertumbuh',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.footnoteRegular.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    timeCapsuleDraft != null
                        ? Icons.edit_outlined
                        : Icons.chevron_right,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
