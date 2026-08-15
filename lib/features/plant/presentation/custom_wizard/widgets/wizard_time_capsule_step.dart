import 'package:flutter/material.dart';
import 'package:plenty/core/utils/widgets/custom_text_field.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_typography.dart';

/// Step 5: Time capsule toggle and future message prompt.
class WizardTimeCapsuleStep extends StatelessWidget {
  final bool enableTimeCapsule;
  final TextEditingController messageController;
  final ValueChanged<bool> onToggle;

  const WizardTimeCapsuleStep({
    super.key,
    required this.enableTimeCapsule,
    required this.messageController,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.pastelPurpleBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_empty,
                  color: AppColors.pastelPurpleText,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aktifkan Time Capsule',
                      style: AppTypography.headline.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Terbuka dalam 60 hari',
                      style: AppTypography.caption1Regular.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: enableTimeCapsule,
                activeTrackColor: AppColors.forest,
                onChanged: onToggle,
              ),
            ],
          ),
        ),
        if (enableTimeCapsule) ...[
          const SizedBox(height: 28),
          CustomTextField(
            controller: messageController,
            label: 'Pesan Rahasia',
            hintText: 'Apa yang kamu rasakan hari ini? Ada harapan untuk dirimu di masa depan?',
            maxLines: 4,
            textInputAction: TextInputAction.done,
          ),
        ],
      ],
    );
  }
}
