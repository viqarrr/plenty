import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';

/// Step 5: Planting/Adoption Date picker and optional Time Capsule note.
class WizardTimeCapsuleStep extends StatelessWidget {
  final DateTime plantedDate;
  final String? timeCapsuleMessage;
  final bool enableTimeCapsule;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<String> onMessageChanged;
  final ValueChanged<bool> onToggleTimeCapsule;

  const WizardTimeCapsuleStep({
    super.key,
    required this.plantedDate,
    this.timeCapsuleMessage,
    required this.enableTimeCapsule,
    required this.onDateChanged,
    required this.onMessageChanged,
    required this.onToggleTimeCapsule,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kapsul Waktu',
            style: AppTypography.displayLarge.copyWith(
              fontSize: 32,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Catat awal mula perjalanan merawat tanaman ini untuk kenangan masa depan.',
            style: AppTypography.bodyRegular.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 24),

          // Time Capsule Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: enableTimeCapsule
                  ? AppColors.pastelGreenBg
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: enableTimeCapsule ? AppColors.forest : AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lock_clock_outlined,
                      color: AppColors.forest,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buat Pesan Kapsul Waktu',
                            style: AppTypography.calloutBold.copyWith(
                              color: AppColors.inkSoft,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Buat pesan/harapan yang akan terbuka otomatis setelah 30 hari.',
                            style: AppTypography.footnoteRegular.copyWith(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: enableTimeCapsule,
                      onChanged: onToggleTimeCapsule,
                      activeThumbColor: AppColors.forest,
                      activeTrackColor: AppColors.forest.withValues(alpha: 0.4),
                    ),
                  ],
                ),
                if (enableTimeCapsule) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    initialValue: timeCapsuleMessage,
                    onChanged: onMessageChanged,
                    maxLines: 3,
                    style: AppTypography.bodyRegular.copyWith(
                      color: AppColors.ink,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Tuliskan harapanmu untuk tanaman ini (misal: "Semoga tumbuh lebat sampai punya 5 daun baru!")...',
                      hintStyle: AppTypography.footnoteRegular.copyWith(
                        color: AppColors.muted,
                      ),
                      filled: true,
                      fillColor: AppColors.canvasDefault,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.forest,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
