import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_typography.dart';

/// Step 3: Location / Room selection & custom room addition.
class WizardAreaStep extends StatelessWidget {
  final String environment;
  final String specificArea;
  final ValueChanged<String> onAreaChanged;

  const WizardAreaStep({
    super.key,
    required this.environment,
    required this.specificArea,
    required this.onAreaChanged,
  });

  @override
  Widget build(BuildContext context) {
    final areas = environment == 'Indoor'
        ? ['Ruang Tamu', 'Dapur', 'Kamar', 'Ruang Kerja']
        : ['Balkon', 'Kebun', 'Serambi', 'Teras'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Area $environment',
              style: AppTypography.headline.copyWith(fontSize: 14),
            ),
            TextButton.icon(
              onPressed: () => _showCustomAreaDialog(context),
              icon: const Icon(Icons.add, size: 16, color: AppColors.forest),
              label: Text(
                'Kustom',
                style: AppTypography.caption1Bold.copyWith(
                  color: AppColors.forest,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: areas.length,
          itemBuilder: (context, index) {
            final areaName = areas[index];
            final isSelected = specificArea == areaName;
            return InkWell(
              onTap: () => onAreaChanged(areaName),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.pastelGreenBg
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.forest : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getRoomIcon(areaName),
                      color: isSelected ? AppColors.forest : AppColors.muted,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      areaName,
                      style: AppTypography.footnoteBold.copyWith(
                        color: isSelected ? AppColors.forest : AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showCustomAreaDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Buat Area Kustom'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Contoh: Kamar Mandi, Gudang...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                final txt = controller.text.trim();
                if (txt.isNotEmpty) {
                  onAreaChanged(txt);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  IconData _getRoomIcon(String room) {
    return switch (room.toLowerCase()) {
      'ruang tamu' => Icons.weekend_outlined,
      'dapur' => Icons.kitchen_outlined,
      'kamar' => Icons.bed_outlined,
      'ruang kerja' => Icons.work_outline,
      'balkon' => Icons.balcony_outlined,
      'kebun' => Icons.yard_outlined,
      'serambi' => Icons.deck_outlined,
      'teras' => Icons.house_outlined,
      _ => Icons.place_outlined,
    };
  }
}
