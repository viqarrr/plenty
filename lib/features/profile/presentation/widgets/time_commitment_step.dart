import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';

/// Step 2 widget of Preferences Flow: Daily time commitment slider.
class TimeCommitmentStep extends StatelessWidget {
  final double timeCommitment;
  final ValueChanged<double> onChanged;

  const TimeCommitmentStep({
    super.key,
    required this.timeCommitment,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Berapa banyak waktu yang bisa kamu luangkan?',
          style: AppTypography.title2Bold.copyWith(
            color: AppColors.ink,
            fontSize: 36,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Geser slider untuk mengatur durasi per hari.',
          style: AppTypography.bodyRegular.copyWith(
            color: AppColors.muted,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 60),
        Card(
          color: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 32.0,
              horizontal: 20.0,
            ),
            child: Column(
              children: [
                Text(
                  '${timeCommitment.toInt()} menit',
                  style: AppTypography.largeTitleBold.copyWith(
                    color: AppColors.forest,
                    fontSize: 40,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'per hari',
                  style: AppTypography.footnoteRegular.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 32),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.forest,
                    inactiveTrackColor: AppColors.border,
                    thumbColor: AppColors.forest,
                    overlayColor: AppColors.forest.withValues(alpha: 0.12),
                  ),
                  child: Slider(
                    value: timeCommitment,
                    min: 5,
                    max: 60,
                    divisions: 11,
                    onChanged: onChanged,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '5 menit',
                      style: AppTypography.footnoteRegular.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      '60 menit',
                      style: AppTypography.footnoteRegular.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
