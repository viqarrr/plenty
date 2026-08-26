import 'dart:io';

import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';

/// Step 1: Input custom plant name, photo upload preview, & initial height.
class WizardNamePhotoStep extends StatelessWidget {
  final String plantName;
  final String? imagePath;
  final double initialHeightCm;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<double> onHeightChanged;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  const WizardNamePhotoStep({
    super.key,
    required this.plantName,
    this.imagePath,
    this.initialHeightCm = 25.0,
    required this.onNameChanged,
    required this.onHeightChanged,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  ImageProvider _resolveImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    } else if (path.startsWith('assets/')) {
      return AssetImage(path);
    } else {
      return FileImage(File(path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nama & Penampilan',
            style: AppTypography.title2Bold.copyWith(
              color: AppColors.inkSoft,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Beri nama panggilan manis untuk tanaman barumu dan tentukan tinggi awalnya.',
            style: AppTypography.bodyRegular.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 28),

          // Photo Upload Avatar
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: onPickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.pastelGreenBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.forest.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      image: imagePath != null && imagePath!.isNotEmpty
                          ? DecorationImage(
                              image: _resolveImage(imagePath!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: imagePath == null || imagePath!.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_a_photo_outlined,
                                color: AppColors.forest,
                                size: 36,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tambah Foto',
                                style: AppTypography.caption1Bold.copyWith(
                                  color: AppColors.forest,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
                if (imagePath != null && imagePath!.isNotEmpty)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: onRemoveImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.pastelRedText,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Name Input Field
          Text(
            'Nama Tanaman *',
            style: AppTypography.calloutBold.copyWith(color: AppColors.inkSoft),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: plantName,
            onChanged: onNameChanged,
            style: AppTypography.bodyRegular.copyWith(color: AppColors.ink),
            decoration: InputDecoration(
              hintText: 'Misal: Monstera Hijau, Sirih Gading Mini...',
              hintStyle: AppTypography.bodyRegular.copyWith(
                color: AppColors.muted,
              ),
              prefixIcon: const Icon(
                Icons.local_florist_outlined,
                color: AppColors.forest,
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.forest,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Initial Height Input Field
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tinggi Tanaman *',
                style: AppTypography.calloutBold.copyWith(
                  color: AppColors.inkSoft,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.pastelGreenBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${initialHeightCm.toStringAsFixed(1)} cm',
                  style: AppTypography.caption1Bold.copyWith(
                    color: AppColors.forest,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: initialHeightCm > 0
                ? initialHeightCm.toStringAsFixed(1)
                : '25.0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) {
              final parsed = double.tryParse(val.replaceAll(',', '.'));
              if (parsed != null && parsed >= 0) {
                onHeightChanged(parsed);
              }
            },
            style: AppTypography.bodyRegular.copyWith(color: AppColors.ink),
            decoration: InputDecoration(
              hintText: 'Misal: 25.0',
              suffixText: 'cm',
              suffixStyle: AppTypography.calloutBold.copyWith(
                color: AppColors.forest,
              ),
              prefixIcon: const Icon(Icons.straighten, color: AppColors.forest),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.forest,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
