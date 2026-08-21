import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/widgets/custom_button.dart';

class AddFirstPlantCtaScreen extends StatelessWidget {
  final VoidCallback onAddFirstPlant;
  final VoidCallback onSkip;
  final bool isLoading;

  const AddFirstPlantCtaScreen({
    super.key,
    required this.onAddFirstPlant,
    required this.onSkip,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Center(
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.forest.withValues(alpha: 0.15),
                  AppColors.emerald.withValues(alpha: 0.25),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.local_florist,
                color: AppColors.forest,
                size: 64,
              ),
            ),
          ),
        ),
        const SizedBox(height: 36),
        Text(
          'Profilmu Sudah Siap!',
          textAlign: TextAlign.center,
          style: AppTypography.displayLarge.copyWith(
            color: AppColors.inkSoft,
            fontSize: 28,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Mulai perjalanan merawat tanamanmu dengan menambahkan tanaman pertamamu sekarang dan dapatkan Badge Spesial!',
            textAlign: TextAlign.center,
            style: AppTypography.bodyRegular.copyWith(
              color: AppColors.muted,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
        const Spacer(),
        CustomButton(
          text: 'Tambah Tanaman Pertama',
          icon: Icons.add,
          height: 54,
          borderRadius: BorderRadius.circular(30),
          isLoading: isLoading,
          onPressed: onAddFirstPlant,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'Nanti Saja (Lewati)',
          isOutlined: true,
          height: 54,
          borderRadius: BorderRadius.circular(30),
          textColor: AppColors.muted,
          onPressed: isLoading ? null : onSkip,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
