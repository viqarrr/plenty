import 'dart:io';

import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/image_picker_helper.dart';
import 'package:plenty/data/models/plant_model.dart';

/// Bottom sheet modal for daily height logging, matching Plenty design language.
class MonitorTinggiInputSheet extends StatefulWidget {
  final PlantModel plant;
  final double lastRecordedHeight;
  final bool isPhotoRequired;
  final bool isEditMode;
  final String? initialNote;
  final String? initialPhotoPath;
  final void Function(double heightCm, String? note, String? photoPath)
  onSubmit;

  const MonitorTinggiInputSheet({
    super.key,
    required this.plant,
    required this.lastRecordedHeight,
    this.isPhotoRequired = false,
    this.isEditMode = false,
    this.initialNote,
    this.initialPhotoPath,
    required this.onSubmit,
  });

  @override
  State<MonitorTinggiInputSheet> createState() =>
      _MonitorTinggiInputSheetState();
}

class _MonitorTinggiInputSheetState extends State<MonitorTinggiInputSheet> {
  late final TextEditingController _heightController;
  late final TextEditingController _noteController;
  late double _currentHeight;
  String? _selectedPhotoPath;
  String? _photoError;

  @override
  void initState() {
    super.initState();
    _currentHeight = widget.lastRecordedHeight > 0
        ? widget.lastRecordedHeight
        : (widget.plant.currentHeightCm > 0
              ? widget.plant.currentHeightCm
              : 30.0);
    _heightController = TextEditingController(
      text: _currentHeight.toStringAsFixed(1),
    );
    _noteController = TextEditingController(text: widget.initialNote ?? '');
    _selectedPhotoPath = widget.initialPhotoPath;
  }

  @override
  void dispose() {
    _heightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _updateHeight(double newHeight) {
    if (newHeight < 0.5) return;
    setState(() {
      _currentHeight = double.parse(newHeight.toStringAsFixed(1));
      _heightController.text = _currentHeight.toStringAsFixed(1);
    });
  }

  Future<void> _pickPhoto() async {
    await ImagePickerHelper.showPickerSheet(
      context: context,
      onImageSelected: (path) {
        setState(() {
          _selectedPhotoPath = path;
          if (path != null && path.isNotEmpty) {
            _photoError = null;
          }
        });
      },
      showRemoveOption: _selectedPhotoPath != null,
    );
  }

  void _handleSave() {
    if (widget.isPhotoRequired &&
        (_selectedPhotoPath == null || _selectedPhotoPath!.isEmpty)) {
      setState(() {
        _photoError = 'Foto tanaman wajib diambil untuk siklus log hari ini';
      });
      return;
    }

    final text = _heightController.text.replaceAll(',', '.');
    final parsed = double.tryParse(text) ?? _currentHeight;
    final note = _noteController.text.trim();

    widget.onSubmit(parsed, note.isNotEmpty ? note : null, _selectedPhotoPath);
    Navigator.of(context).pop();
  }

  Widget _buildPhotoPreview(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.local_florist, color: AppColors.forest, size: 36),
      );
    } else if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.local_florist, color: AppColors.forest, size: 36),
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.local_florist, color: AppColors.forest, size: 36),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEditMode
                            ? 'Koreksi Log: ${widget.plant.nickname}'
                            : widget.plant.nickname,
                        style: AppTypography.title2Bold.copyWith(
                          color: AppColors.inkSoft,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.isEditMode
                            ? 'Perbarui nilai tinggi, foto, atau catatan harian'
                            : 'Tinggi terakhir: ${widget.lastRecordedHeight.toStringAsFixed(1)} cm',
                        style: AppTypography.caption1Regular.copyWith(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.muted,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Numeric Height Input with Stepper
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.canvasDefault,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildStepperButton(
                    icon: Icons.remove,
                    onTap: () => _updateHeight(_currentHeight - 0.5),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _heightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          style: AppTypography.displayLarge.copyWith(
                            color: AppColors.forest,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(
                              val.replaceAll(',', '.'),
                            );
                            if (parsed != null && parsed >= 0) {
                              _currentHeight = parsed;
                            }
                          },
                        ),
                        Text(
                          'centimeter',
                          style: AppTypography.caption1Regular.copyWith(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStepperButton(
                    icon: Icons.add,
                    onTap: () => _updateHeight(_currentHeight + 0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.isPhotoRequired
                    ? AppColors.pastelGreenBg
                    : AppColors.canvasDefault,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isPhotoRequired
                      ? AppColors.forest.withValues(alpha: 0.25)
                      : AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedPhotoPath == null ||
                      _selectedPhotoPath!.isEmpty) ...[
                    Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: _pickPhoto,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_a_photo_outlined,
                                color: AppColors.forest,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.isPhotoRequired
                                    ? 'Ambil / Unggah Foto Perkembangan Tanaman *'
                                    : 'Ambil / Unggah Foto Tanaman (Opsional)',
                                style: AppTypography.caption1Bold.copyWith(
                                  color: AppColors.forest,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: _buildPhotoPreview(_selectedPhotoPath!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Foto berhasil dipilih',
                                style: AppTypography.caption1Bold.copyWith(
                                  color: AppColors.inkSoft,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: _pickPhoto,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Ganti Foto',
                                      style: AppTypography.caption1Bold
                                          .copyWith(
                                            color: AppColors.forest,
                                            fontSize: 12,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  if (!widget.isPhotoRequired)
                                    TextButton(
                                      onPressed: () => setState(
                                        () => _selectedPhotoPath = null,
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Hapus',
                                        style: AppTypography.caption1Bold
                                            .copyWith(
                                              color: AppColors.error,
                                              fontSize: 12,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (_photoError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _photoError!,
                      style: AppTypography.caption1Regular.copyWith(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Optional Note Input
            TextFormField(
              controller: _noteController,
              style: AppTypography.bodyRegular.copyWith(
                color: AppColors.inkSoft,
              ),
              decoration: InputDecoration(
                hintText:
                    'Tambahkan catatan opsional (mis. Tunas daun baru)...',
                hintStyle: AppTypography.caption1Regular.copyWith(
                  color: AppColors.muted,
                ),
                prefixIcon: Icon(Icons.notes),
                filled: true,
                fillColor: AppColors.canvasDefault,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forest,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isEditMode
                          ? 'Simpan Perubahan'
                          : 'Simpan Perkembangan (+15 XP)',
                      style: AppTypography.calloutBold.copyWith(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.forest, size: 20),
        ),
      ),
    );
  }
}
