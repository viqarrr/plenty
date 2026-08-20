import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/data/models/plant_model.dart';

/// Modal bottom sheet confirming user intent before permanently deleting a plant from collection.
class DeletePlantSheet extends StatelessWidget {
  final PlantModel plant;
  final VoidCallback onConfirmDelete;

  const DeletePlantSheet({
    super.key,
    required this.plant,
    required this.onConfirmDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.canvasDefault,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.pastelRedBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.pastelRedText.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: AppColors.pastelRedText,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Hapus ${plant.nickname}?',
            textAlign: TextAlign.center,
            style: AppTypography.title2Bold.copyWith(
              fontSize: 20,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Apakah kamu yakin ingin menghapus tanaman ini dari koleksimu? Seluruh riwayat pertumbuhan, jadwal perawatan, dan kapsul waktu terkait akan dihapus secara permanen.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyRegular.copyWith(
              fontSize: 14,
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          CustomButton(
            text: 'Ya, Hapus Tanaman',
            backgroundColor: AppColors.pastelRedText,
            icon: Icons.delete_outline,
            height: 48,
            borderRadius: BorderRadius.circular(24),
            onPressed: () {
              Navigator.of(context).pop();
              onConfirmDelete();
            },
          ),
          const SizedBox(height: 10),
          CustomButton(
            text: 'Batal',
            isOutlined: true,
            height: 48,
            borderRadius: BorderRadius.circular(24),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
