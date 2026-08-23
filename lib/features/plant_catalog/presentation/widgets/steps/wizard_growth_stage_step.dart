import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';

/// Wizard Step: Select plant growth origin (seedling vs mature plant) and planted date.
class WizardGrowthStageStep extends StatelessWidget {
  final String selectedStage;
  final ValueChanged<String> onStageChanged;
  final DateTime? plantedDate;
  final ValueChanged<DateTime>? onDateChanged;

  const WizardGrowthStageStep({
    super.key,
    required this.selectedStage,
    required this.onStageChanged,
    this.plantedDate,
    this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSeed = selectedStage == 'seed';
    final effectivePlantedDate = plantedDate ?? DateTime.now();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Asal Pertumbuhan',
            style: AppTypography.title2Bold.copyWith(
              color: AppColors.inkSoft,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bagaimana kondisi tanamanmu saat pertama kali mulai dirawat?',
            style: AppTypography.bodyRegular.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 28),

          // Option 1: Dari Bibit / Benih
          _GrowthStageCard(
            title: 'Ditanam dari Bibit / Benih',
            subtitle:
                'Kamu menanam dan merawatnya dari biji, umbi, spora, atau tunas kecil sejak awal.',
            icon: Icons.spa_outlined,
            isSelected: isSeed,
            onTap: () {
              onStageChanged('seed');
              onDateChanged?.call(DateTime.now());
            },
          ),
          const SizedBox(height: 16),

          // Option 2: Sudah Tumbuh Besar
          _GrowthStageCard(
            title: 'Sudah Tumbuh Besar',
            subtitle:
                'Tanaman hidup atau tanaman dewasa yang sudah berakar kokoh dan memiliki daun saat kamu adopsi.',
            icon: Icons.park_outlined,
            isSelected: !isSeed,
            onTap: () => onStageChanged('mature'),
          ),

          // Date picker when plant is already grown
          if (!isSeed) ...[
            const SizedBox(height: 20),
            _PlantedDatePickerCard(
              plantedDate: effectivePlantedDate,
              onDateChanged: onDateChanged,
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _GrowthStageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GrowthStageCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.pastelGreenBg.withValues(alpha: 0.6)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.forest : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.forest.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.forest
                        : AppColors.pastelGreenBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected ? Colors.white : AppColors.forest,
                  ),
                ),
                const Spacer(),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected ? AppColors.forest : AppColors.muted,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTypography.calloutBold.copyWith(
                color: isSelected ? AppColors.forest : AppColors.inkSoft,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.bodyRegular.copyWith(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Date picker card allowing user to specify when an established plant was first planted/acquired.
class _PlantedDatePickerCard extends StatelessWidget {
  final DateTime plantedDate;
  final ValueChanged<DateTime>? onDateChanged;

  const _PlantedDatePickerCard({
    required this.plantedDate,
    required this.onDateChanged,
  });

  String _formatDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _calculateAge(DateTime date) {
    final now = DateTime.now();
    final startDate = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(startDate).inDays;

    if (days <= 0) return '1 Hari (Hari ini)';
    if (days < 30) return '$days Hari';
    if (days < 365) {
      final months = days ~/ 30;
      final remDays = days % 30;
      return remDays > 0 ? '$months Bln $remDays Hr' : '$months Bulan';
    }
    final years = days ~/ 365;
    final remMonths = (days % 365) ~/ 30;
    return remMonths > 0 ? '$years Thn $remMonths Bln' : '$years Tahun';
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: plantedDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.forest,
              onPrimary: Colors.white,
              onSurface: AppColors.inkSoft,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      onDateChanged?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.pastelGreenBg.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.forest.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 20,
                color: AppColors.forest,
              ),
              const SizedBox(width: 8),
              Text(
                'Mulai Ditanam / Diadopsi Kapan?',
                style: AppTypography.calloutBold.copyWith(
                  color: AppColors.forest,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tentukan perkiraan awal tanaman mulai kamu rawat untuk menghitung usianya.',
            style: AppTypography.caption1Regular.copyWith(
              color: AppColors.muted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => _pickDate(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.forest.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(plantedDate),
                          style: AppTypography.bodyBold.copyWith(
                            color: AppColors.inkSoft,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Estimasi Usia: ${_calculateAge(plantedDate)}',
                          style: AppTypography.caption1Regular.copyWith(
                            color: AppColors.forest,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.pastelGreenBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit_calendar_rounded,
                      size: 18,
                      color: AppColors.forest,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
