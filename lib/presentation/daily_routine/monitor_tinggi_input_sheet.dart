import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/core/widgets/custom_text_field.dart';
import 'package:plenty/data/models/plant_model.dart';

class MonitorTinggiInputSheet extends StatefulWidget {
  final PlantModel plant;
  final void Function(double heightCm, String? note, String? photoPath)
      onSubmit;

  const MonitorTinggiInputSheet({
    super.key,
    required this.plant,
    required this.onSubmit,
  });

  @override
  State<MonitorTinggiInputSheet> createState() =>
      _MonitorTinggiInputSheetState();
}

class _MonitorTinggiInputSheetState extends State<MonitorTinggiInputSheet> {
  final _noteController = TextEditingController();
  late double _currentHeight;

  @override
  void initState() {
    super.initState();
    _currentHeight = widget.plant.currentHeightCm > 0
        ? widget.plant.currentHeightCm
        : 30.0;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
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
              Text(
                'Catat Tinggi ${widget.plant.nickname}',
                style: AppTypography.title2Bold.copyWith(fontSize: 18),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.pastelGreenBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${_currentHeight.toStringAsFixed(1)} cm',
                  style: AppTypography.title2Bold.copyWith(
                    color: AppColors.forest,
                  ),
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
              value: _currentHeight,
              min: 5.0,
              max: 200.0,
              divisions: 195,
              onChanged: (val) => setState(() => _currentHeight = val),
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _noteController,
            label: 'Catatan Pertumbuhan (Opsional)',
            hintText: 'e.g. Tunas daun baru mulai mekar',
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Simpan Perkembangan (+15 XP)',
            height: 50,
            borderRadius: BorderRadius.circular(25),
            onPressed: () {
              widget.onSubmit(
                _currentHeight,
                _noteController.text.trim().isNotEmpty
                    ? _noteController.text.trim()
                    : null,
                null,
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
