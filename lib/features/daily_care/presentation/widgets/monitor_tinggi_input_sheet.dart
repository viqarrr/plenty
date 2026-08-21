import 'dart:io';

import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/image_picker_helper.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/core/widgets/custom_text_field.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';

class MonitorTinggiInputSheet extends StatefulWidget {
  final PlantModel plant;
  final double? lastRecordedHeight;
  final bool isPhotoRequired;
  final bool isEditMode;
  final String? initialNote;
  final String? initialPhotoPath;
  final void Function(double heightCm, String? note, String? photoPath)
      onSubmit;

  const MonitorTinggiInputSheet({
    super.key,
    required this.plant,
    this.lastRecordedHeight,
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
  late final TextEditingController _noteController;
  late final TextEditingController _heightController;
  late double _currentHeight;
  String? _selectedPhotoPath;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote ?? '');
    _currentHeight = widget.lastRecordedHeight ??
        (widget.plant.currentHeightCm > 0
            ? widget.plant.currentHeightCm
            : 30.0);
    _heightController = TextEditingController(
      text: _currentHeight.toStringAsFixed(1),
    );
    _selectedPhotoPath = widget.initialPhotoPath;
  }

  @override
  void dispose() {
    _noteController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Widget _buildPhotoPreview(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.local_florist, color: AppColors.forest),
      );
    } else if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.local_florist, color: AppColors.forest),
      );
    } else {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              const Icon(Icons.local_florist, color: AppColors.forest),
        );
      }
    }
    return const Icon(Icons.image, color: AppColors.forest);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
              children: [
                const Icon(Icons.straighten, color: AppColors.forest, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Buat Log Harian ${widget.plant.nickname}',
                    style: AppTypography.title2Bold.copyWith(fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ukur tinggi tanaman dari permukaan tanah hingga ujung daun tertinggi.',
              style: AppTypography.footnoteRegular.copyWith(
                color: AppColors.muted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),

            // Height input row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tinggi Saat Ini',
                  style: AppTypography.calloutBold.copyWith(
                    color: AppColors.inkSoft,
                  ),
                ),
                Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pastelGreenBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.forest.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _heightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.end,
                          style: AppTypography.title2Bold.copyWith(
                            color: AppColors.forest,
                            fontSize: 16,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                          onChanged: (val) {
                            final parsed =
                                double.tryParse(val.replaceAll(',', '.'));
                            if (parsed != null && parsed > 0) {
                              setState(() {
                                _currentHeight = parsed;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'cm',
                        style: AppTypography.title2Bold.copyWith(
                          color: AppColors.forest,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.forest,
                inactiveTrackColor: AppColors.border,
                thumbColor: AppColors.forest,
              ),
              child: Slider(
                value: _currentHeight.clamp(5.0, 200.0),
                min: 5.0,
                max: 200.0,
                divisions: 195,
                onChanged: (val) {
                  setState(() {
                    _currentHeight = val;
                    _heightController.text = val.toStringAsFixed(1);
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Photo Picker Section
            Text(
              'Foto Perkembangan Tanaman',
              style: AppTypography.calloutBold.copyWith(
                color: AppColors.inkSoft,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedPhotoPath == null)
              InkWell(
                onTap: () {
                  ImagePickerHelper.showPickerSheet(
                    context: context,
                    showRemoveOption: false,
                    onImageSelected: (path) {
                      if (path != null) {
                        setState(() => _selectedPhotoPath = path);
                      }
                    },
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.canvasDefault,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.forest.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_a_photo_outlined,
                        color: AppColors.forest,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isPhotoRequired
                            ? 'Ambil / Unggah Foto Perkembangan *'
                            : 'Ambil / Unggah Foto (Opsional)',
                        style: AppTypography.caption1Bold.copyWith(
                          color: AppColors.forest,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.canvasDefault,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 56,
                        height: 56,
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
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  ImagePickerHelper.showPickerSheet(
                                    context: context,
                                    showRemoveOption: !widget.isPhotoRequired,
                                    onImageSelected: (path) {
                                      setState(
                                          () => _selectedPhotoPath = path);
                                    },
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Ganti Foto',
                                  style: AppTypography.caption1Bold.copyWith(
                                    color: AppColors.forest,
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              if (!widget.isPhotoRequired) ...[
                                const SizedBox(width: 16),
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _selectedPhotoPath = null),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Hapus',
                                    style: AppTypography.caption1Bold.copyWith(
                                      color: AppColors.pastelRedText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Note Input
            CustomTextField(
              controller: _noteController,
              label: 'Catatan Pertumbuhan (Opsional)',
              hintText: 'e.g. Tunas daun baru mulai mekar',
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Submit Button
            CustomButton(
              text: widget.isEditMode
                  ? 'Simpan Perubahan'
                  : 'Simpan Perkembangan (+15 XP)',
              height: 50,
              borderRadius: BorderRadius.circular(25),
              onPressed: () {
                final parsedHeight = double.tryParse(
                  _heightController.text.replaceAll(',', '.'),
                );
                final finalHeight = (parsedHeight != null && parsedHeight > 0)
                    ? parsedHeight
                    : _currentHeight;

                widget.onSubmit(
                  finalHeight,
                  _noteController.text.trim().isNotEmpty
                      ? _noteController.text.trim()
                      : null,
                  _selectedPhotoPath,
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
