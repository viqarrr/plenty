import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/core/widgets/custom_text_field.dart';
import 'package:plenty/features/garden/domain/models/time_capsule_model.dart';

class TimeCapsuleModal extends StatefulWidget {
  final TimeCapsuleDraft? initialDraft;

  const TimeCapsuleModal({super.key, this.initialDraft});

  @override
  State<TimeCapsuleModal> createState() => _TimeCapsuleModalState();
}

class _TimeCapsuleModalState extends State<TimeCapsuleModal> {
  final _messageController = TextEditingController();
  int _selectedMonths = 3;

  @override
  void initState() {
    super.initState();
    if (widget.initialDraft != null) {
      _messageController.text = widget.initialDraft!.message;
      _selectedMonths = widget.initialDraft!.durationMonths;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
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
              const Icon(Icons.lock_clock, color: AppColors.forest, size: 24),
              const SizedBox(width: 10),
              Text(
                'Kapsul Waktu Tanaman',
                style: AppTypography.title2Bold.copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tulis pesan, harapan, atau catatan saat pertama kali mengadopsi tanaman ini. Pesan akan terkunci dan dibuka saat waktu jatuh tempo.',
            style: AppTypography.footnoteRegular.copyWith(
              color: AppColors.muted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _messageController,
            label: 'Pesan Kapsul Waktu',
            hintText: 'e.g. Semoga tumbuh subur dan daunnya makin rimbun ya!',
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Durasi Penguncian',
            style: AppTypography.footnoteBold.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 10),
          Row(
            children: [1, 3, 6, 12].map((months) {
              final isSelected = _selectedMonths == months;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () => setState(() => _selectedMonths = months),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.forest
                            : AppColors.canvasDefault,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.forest
                              : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$months Bln',
                          style: AppTypography.caption1Bold.copyWith(
                            color: isSelected ? Colors.white : AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          CustomButton(
            text: 'Simpan Kapsul Waktu',
            height: 50,
            borderRadius: BorderRadius.circular(25),
            onPressed: () {
              final msg = _messageController.text.trim();
              if (msg.isEmpty) {
                Navigator.of(context).pop();
                return;
              }
              Navigator.of(context).pop(
                TimeCapsuleDraft(
                  message: msg,
                  durationMonths: _selectedMonths,
                ),
              );
            },
          ),
          if (widget.initialDraft != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(TimeCapsuleDraft(message: '', durationMonths: 0));
              },
              child: Text(
                'Hapus Kapsul Waktu',
                style: AppTypography.footnoteBold.copyWith(
                  color: AppColors.pastelRedText,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
