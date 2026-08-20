import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';

/// Utility helper providing standardized Camera & Gallery modal bottom sheets,
/// with support for sample preset photos (ideal for emulator testing).
class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  static const List<Map<String, String>> samplePresets = [
    {
      'label': 'Monstera Tropis',
      'url':
          'https://images.unsplash.com/photo-1614594975525-e45190c55d0b?w=600&auto=format&fit=crop&q=80',
    },
    {
      'label': 'Snake Plant / Sansevieria',
      'url':
          'https://images.unsplash.com/photo-1599598425947-320b9829eb86?w=600&auto=format&fit=crop&q=80',
    },
    {
      'label': 'Pothos / Sirih Gading',
      'url':
          'https://images.unsplash.com/photo-1596547609652-9cf5d8d76921?w=600&auto=format&fit=crop&q=80',
    },
    {
      'label': 'Calathea Ornata',
      'url':
          'https://images.unsplash.com/photo-1598880940371-c756e015fea1?w=600&auto=format&fit=crop&q=80',
    },
  ];

  /// Opens a standardized modal bottom sheet to pick an image from Camera, Gallery, or Preset.
  static Future<void> showPickerSheet({
    required BuildContext context,
    required ValueChanged<String?> onImageSelected,
    bool showRemoveOption = false,
  }) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
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
            const SizedBox(height: 16),
            Text(
              'Pilih Sumber Foto',
              style: AppTypography.title2Bold.copyWith(
                fontSize: 18,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.pastelGreenBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: AppColors.forest),
              ),
              title: Text('Kamera', style: AppTypography.calloutBold),
              subtitle: Text(
                'Ambil foto tanaman langsung',
                style: AppTypography.caption1Regular.copyWith(color: AppColors.muted),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                try {
                  final picked = await _picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1200,
                    maxHeight: 1200,
                    imageQuality: 85,
                  );
                  if (picked != null) {
                    onImageSelected(picked.path);
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal membuka kamera: $e'),
                      backgroundColor: AppColors.pastelRedText,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.pastelGreenBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library, color: AppColors.forest),
              ),
              title: Text('Galeri Foto', style: AppTypography.calloutBold),
              subtitle: Text(
                'Pilih dari album foto perangkat / emulator',
                style: AppTypography.caption1Regular.copyWith(color: AppColors.muted),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                try {
                  final picked = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1200,
                    maxHeight: 1200,
                    imageQuality: 85,
                  );
                  if (picked != null) {
                    onImageSelected(picked.path);
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal membuka galeri: $e'),
                      backgroundColor: AppColors.pastelRedText,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.pastelGreenBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.forest),
              ),
              title: Text('Foto Contoh / Demo', style: AppTypography.calloutBold),
              subtitle: Text(
                'Pilih contoh foto tanaman (cepat untuk test emulator)',
                style: AppTypography.caption1Regular.copyWith(color: AppColors.muted),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showSamplePresetsModal(context, onImageSelected);
              },
            ),
            if (showRemoveOption) ...[
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.pastelRedBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline, color: AppColors.pastelRedText),
                ),
                title: Text(
                  'Hapus Foto',
                  style: AppTypography.calloutBold.copyWith(color: AppColors.pastelRedText),
                ),
                subtitle: Text(
                  'Gunakan foto default',
                  style: AppTypography.caption1Regular.copyWith(color: AppColors.muted),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onImageSelected(null);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  static void _showSamplePresetsModal(
    BuildContext context,
    ValueChanged<String?> onImageSelected,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (presetContext) => Container(
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
            const SizedBox(height: 16),
            Text(
              'Pilih Foto Contoh',
              style: AppTypography.title2Bold.copyWith(
                fontSize: 18,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 16),
            ...samplePresets.map(
              (preset) => ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    preset['url']!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 44,
                      height: 44,
                      color: AppColors.pastelGreenBg,
                      child: const Icon(Icons.local_florist, color: AppColors.forest),
                    ),
                  ),
                ),
                title: Text(preset['label']!, style: AppTypography.calloutBold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.of(presetContext).pop();
                  onImageSelected(preset['url']!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
