import 'dart:io';
import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/image_picker_helper.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';

/// Modal bottom sheet allowing users to edit plant nickname and upload/change cover photo.
class EditPlantSheet extends StatefulWidget {
  final PlantModel plant;
  final void Function(String newNickname, String? newPhotoPath, bool photoChanged)
      onSave;

  const EditPlantSheet({
    super.key,
    required this.plant,
    required this.onSave,
  });

  @override
  State<EditPlantSheet> createState() => _EditPlantSheetState();
}

class _EditPlantSheetState extends State<EditPlantSheet> {
  late final TextEditingController _nameController;
  String? _currentPhoto;
  bool _photoChanged = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plant.nickname);
    _currentPhoto = widget.plant.coverPhotoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _openImagePicker() {
    ImagePickerHelper.showPickerSheet(
      context: context,
      showRemoveOption: _currentPhoto != null && _currentPhoto!.isNotEmpty,
      onImageSelected: (path) {
        setState(() {
          _currentPhoto = path;
          _photoChanged = true;
        });
      },
    );
  }

  Widget _buildPhotoPreview() {
    final photo = _currentPhoto;
    return GestureDetector(
      onTap: _openImagePicker,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: AppColors.pastelGreenBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.forest.withValues(alpha: 0.3),
                width: 3,
              ),
            ),
            child: ClipOval(
              child: (photo != null && photo.isNotEmpty)
                  ? (photo.startsWith('http://') || photo.startsWith('https://'))
                      ? Image.network(
                          photo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.local_florist,
                            color: AppColors.forest,
                            size: 48,
                          ),
                        )
                      : photo.startsWith('assets/')
                          ? Image.asset(
                              photo,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.local_florist,
                                color: AppColors.forest,
                                size: 48,
                              ),
                            )
                          : Image.file(
                              File(photo),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.local_florist,
                                color: AppColors.forest,
                                size: 48,
                              ),
                            )
                  : const Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.forest,
                      size: 44,
                    ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppColors.forest,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNameValid = _nameController.text.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: const BoxDecoration(
        color: AppColors.canvasDefault,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Tanaman',
                  style: AppTypography.title2Bold.copyWith(
                    fontSize: 20,
                    color: AppColors.inkSoft,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.muted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(child: _buildPhotoPreview()),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _openImagePicker,
                icon: const Icon(Icons.upload_file, size: 16, color: AppColors.forest),
                label: Text(
                  'Upload / Ganti Foto',
                  style: AppTypography.caption1Bold.copyWith(color: AppColors.forest),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nama Panggilan Tanaman *',
              style: AppTypography.calloutBold.copyWith(color: AppColors.inkSoft),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Contoh: Monsty, Sirih Gading Cantik',
                hintStyle: AppTypography.bodyRegular.copyWith(color: AppColors.muted),
                prefixIcon: const Icon(Icons.drive_file_rename_outline, color: AppColors.forest),
                suffixIcon: _nameController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _nameController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.forest, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 28),
            CustomButton(
              text: 'Simpan Perubahan',
              icon: Icons.check_circle_outline,
              height: 48,
              borderRadius: BorderRadius.circular(24),
              onPressed: isNameValid
                  ? () {
                      final newName = _nameController.text.trim();
                      widget.onSave(newName, _currentPhoto, _photoChanged);
                      Navigator.of(context).pop();
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
