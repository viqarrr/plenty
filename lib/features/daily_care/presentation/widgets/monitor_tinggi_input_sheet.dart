import 'dart:io';

import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/core/utils/image_picker_helper.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/core/widgets/custom_text_field.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';

/// Modern, intuitive bottom sheet modal for logging and updating plant height.
/// Features relative slider adjustments (-25 cm to +25 cm), tactile steppers,
/// prominent square photo preview with direct controls, and clean visual hierarchy.
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
  late double _baseHeight;
  late double _currentHeight;
  String? _selectedPhotoPath;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote ?? '');
    _baseHeight = widget.lastRecordedHeight ??
        (widget.plant.currentHeightCm > 0
            ? widget.plant.currentHeightCm
            : 30.0);
    _currentHeight = _baseHeight;
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

  double get _sliderMin {
    final relMin = (_baseHeight - 25.0).clamp(1.0, 9999.0);
    return _currentHeight < relMin ? (_currentHeight - 5.0).clamp(1.0, 9999.0) : relMin;
  }

  double get _sliderMax {
    final relMax = _baseHeight + 25.0;
    return _currentHeight > relMax ? _currentHeight + 5.0 : relMax;
  }

  void _updateHeight(double newHeight) {
    setState(() {
      _currentHeight = double.parse(newHeight.toStringAsFixed(1));
      _heightController.text = _currentHeight.toStringAsFixed(1);
    });
  }

  void _onManualHeightChanged(String val) {
    final parsed = double.tryParse(val.replaceAll(',', '.'));
    if (parsed != null && parsed > 0) {
      setState(() {
        _currentHeight = parsed;
      });
    }
  }

  Future<void> _pickPhoto() async {
    await ImagePickerHelper.showPickerSheet(
      context: context,
      showRemoveOption: !widget.isPhotoRequired && _selectedPhotoPath != null,
      onImageSelected: (path) {
        setState(() => _selectedPhotoPath = path);
      },
    );
  }

  Widget _buildPhotoPreview(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.local_florist_rounded, color: AppColors.forest),
      );
    } else if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.local_florist_rounded, color: AppColors.forest),
      );
    } else {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              const Icon(Icons.local_florist_rounded, color: AppColors.forest),
        );
      }
    }
    return const Icon(Icons.image_rounded, color: AppColors.forest);
  }

  @override
  Widget build(BuildContext context) {
    final delta = _currentHeight - _baseHeight;
    final isDeltaPositive = delta > 0.05;
    final isDeltaNegative = delta < -0.05;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Grab Handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Section: Title & Plant Tag
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.pastelGreenBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.straighten_rounded,
                    color: AppColors.forest,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEditMode
                            ? 'Edit Log Harian'
                            : 'Buat Log Harian',
                        style: AppTypography.title2Bold.copyWith(
                          color: AppColors.inkSoft,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.plant.nickname,
                        style: AppTypography.calloutBold.copyWith(
                          color: AppColors.forest,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.muted,
                    size: 22,
                  ),
                  onPressed: () => context.pop(),
                  tooltip: 'Tutup',
                ),
              ],
            ),

            const SizedBox(height: 8),
            Text(
              'Ukur tinggi tanaman dari permukaan tanah hingga ujung daun tertinggi.',
              style: AppTypography.footnoteRegular.copyWith(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 20),

            // -----------------------------------------------------------------
            // HEIGHT INPUT HERO SECTION
            // -----------------------------------------------------------------
            Column(
              children: [
                // Label
                Text(
                  'Tinggi Saat Ini',
                  style: AppTypography.caption1Bold.copyWith(
                    color: AppColors.muted,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Large Interactive Counter with direct manual editing
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pastelGreenBg.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.forest.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _heightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          style: AppTypography.displayLarge.copyWith(
                            color: AppColors.forest,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                          onChanged: _onManualHeightChanged,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'cm',
                        style: AppTypography.title2Bold.copyWith(
                          color: AppColors.forest.withValues(alpha: 0.8),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Dynamic Delta Pill compared to previous height
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDeltaPositive
                        ? AppColors.pastelGreenBg
                        : (isDeltaNegative
                            ? AppColors.pastelYellowBg
                            : AppColors.canvasDefault),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isDeltaPositive
                        ? '▲ +${delta.toStringAsFixed(1)} cm dari sebelumnya (${_baseHeight.toStringAsFixed(1)} cm)'
                        : (isDeltaNegative
                            ? '▼ ${delta.toStringAsFixed(1)} cm dari sebelumnya (${_baseHeight.toStringAsFixed(1)} cm)'
                            : 'Sama dengan tinggi sebelumnya (${_baseHeight.toStringAsFixed(1)} cm)'),
                    style: AppTypography.caption1Bold.copyWith(
                      color: isDeltaPositive
                          ? AppColors.pastelGreenText
                          : (isDeltaNegative
                              ? AppColors.pastelYellowText
                              : AppColors.muted),
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Slider with (-) and (+) Stepper Buttons
                Row(
                  children: [
                    // (-) Decrement Button
                    _buildStepperButton(
                      icon: Icons.remove_rounded,
                      tooltip: 'Kurangi 0.5 cm',
                      onTap: () {
                        final next = (_currentHeight - 0.5)
                            .clamp(_sliderMin, _sliderMax);
                        _updateHeight(next);
                      },
                    ),

                    // Relative Dynamic Slider
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.forest,
                          inactiveTrackColor: AppColors.border,
                          thumbColor: AppColors.forest,
                          trackHeight: 6.0,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 11.0,
                            elevation: 2.0,
                          ),
                          overlayColor: AppColors.forest.withValues(alpha: 0.12),
                        ),
                        child: Slider(
                          value: _currentHeight.clamp(_sliderMin, _sliderMax),
                          min: _sliderMin,
                          max: _sliderMax,
                          divisions: ((_sliderMax - _sliderMin) * 2)
                              .round()
                              .clamp(10, 500),
                          onChanged: _updateHeight,
                        ),
                      ),
                    ),

                    // (+) Increment Button
                    _buildStepperButton(
                      icon: Icons.add_rounded,
                      tooltip: 'Tambah 0.5 cm',
                      onTap: () {
                        final next = (_currentHeight + 0.5)
                            .clamp(_sliderMin, _sliderMax);
                        _updateHeight(next);
                      },
                    ),
                  ],
                ),

                // Slider Boundary Labels
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 46),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_sliderMin.toStringAsFixed(1)} cm',
                        style: AppTypography.footnoteRegular.copyWith(
                          color: AppColors.mutedGray,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'Basis: ${_baseHeight.toStringAsFixed(1)} cm',
                        style: AppTypography.footnoteRegular.copyWith(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_sliderMax.toStringAsFixed(1)} cm',
                        style: AppTypography.footnoteRegular.copyWith(
                          color: AppColors.mutedGray,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 20),

            // -----------------------------------------------------------------
            // PHOTO UPLOAD SECTION
            // -----------------------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Foto Perkembangan',
                  style: AppTypography.calloutBold.copyWith(
                    color: AppColors.inkSoft,
                    fontSize: 14,
                  ),
                ),
                if (widget.isPhotoRequired)
                  Text(
                    '* Wajib diisi',
                    style: AppTypography.footnoteRegular.copyWith(
                      color: AppColors.pastelRedText,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (_selectedPhotoPath == null)
              // Empty State: Clean, dashed/subtle styled upload prompt
              InkWell(
                onTap: _pickPhoto,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.canvasBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.pastelGreenBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_a_photo_outlined,
                          color: AppColors.forest,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isPhotoRequired
                                ? 'Ambil / Unggah Foto Perkembangan *'
                                : 'Ambil / Unggah Foto (Opsional)',
                            style: AppTypography.calloutBold.copyWith(
                              color: AppColors.forest,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kamera atau Galeri Foto',
                            style: AppTypography.footnoteRegular.copyWith(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              // Filled State: Prominent Square Preview with Inline Control Buttons
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.canvasBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    // Square photo preview
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: AppColors.borderLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: _buildPhotoPreview(_selectedPhotoPath!),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Controls & Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.forest,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Foto terpilih',
                                style: AppTypography.caption1Bold.copyWith(
                                  color: AppColors.forest,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              // "Ganti Foto" Button
                              OutlinedButton.icon(
                                onPressed: _pickPhoto,
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 15,
                                  color: AppColors.forest,
                                ),
                                label: Text(
                                  'Ganti Foto',
                                  style: AppTypography.caption1Bold.copyWith(
                                    color: AppColors.forest,
                                    fontSize: 12,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppColors.forest,
                                    width: 1.2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),

                              // "Hapus" Button
                              if (!widget.isPhotoRequired) ...[
                                const SizedBox(width: 10),
                                TextButton.icon(
                                  onPressed: () =>
                                      setState(() => _selectedPhotoPath = null),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 16,
                                    color: AppColors.pastelRedText,
                                  ),
                                  label: Text(
                                    'Hapus',
                                    style: AppTypography.caption1Bold.copyWith(
                                      color: AppColors.pastelRedText,
                                      fontSize: 12,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
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

            const SizedBox(height: 20),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 20),

            // -----------------------------------------------------------------
            // NOTE INPUT SECTION
            // -----------------------------------------------------------------
            CustomTextField(
              controller: _noteController,
              label: 'Catatan Pertumbuhan (Opsional)',
              hintText: 'e.g. Tunas daun baru mulai mekar',
              maxLines: 2,
            ),

            const SizedBox(height: 24),

            // -----------------------------------------------------------------
            // SUBMIT BUTTON
            // -----------------------------------------------------------------
            CustomButton(
              text: widget.isEditMode
                  ? 'Simpan Perubahan'
                  : 'Simpan Perkembangan (+15 XP)',
              height: 52,
              borderRadius: BorderRadius.circular(26),
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
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.canvasBackground,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.border,
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.forest,
            size: 20,
          ),
        ),
      ),
    );
  }
}
