import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';

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
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.pastelRedBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever_outlined,
                color: AppColors.pastelRedText,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Hapus Tanaman?',
            textAlign: TextAlign.center,
            style: AppTypography.title2Bold.copyWith(
              color: AppColors.inkSoft,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Apakah Anda yakin ingin menghapus "${plant.nickname}" dari koleksi kebun Anda? Riwayat perawatan dan foto juga akan dihapus.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyRegular.copyWith(
                color: AppColors.muted,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Ya, Hapus Tanaman',
            backgroundColor: AppColors.pastelRedText,
            icon: Icons.delete_outline,
            height: 48,
            borderRadius: BorderRadius.circular(24),
            onPressed: () {
              context.pop();
              onConfirmDelete();
            },
          ),
          const SizedBox(height: 10),
          CustomButton(
            text: 'Batal',
            isOutlined: true,
            height: 48,
            borderRadius: BorderRadius.circular(24),
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}
