import 'package:flutter/material.dart';
import 'package:plenty/core/utils/widgets/custom_text_field.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_typography.dart';

/// Step 4: Photo representation and custom plant naming.
class WizardNamePhotoStep extends StatelessWidget {
  final TextEditingController nameController;

  const WizardNamePhotoStep({super.key, required this.nameController});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto Tanaman',
          style: AppTypography.headline.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 12),
        // Mock Photo Container
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_a_photo_outlined,
                  color: AppColors.muted,
                  size: 36,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add Photo',
                  style: AppTypography.caption1Bold.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        CustomTextField(
          controller: nameController,
          label: 'Nama Tanaman',
          hintText: 'Contoh: Si Hijau, Monsty...',
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Nama tanaman tidak boleh kosong';
            }
            return null;
          },
        ),
      ],
    );
  }
}
