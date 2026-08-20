import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';

/// Step 3: Room / Zone selection with interactive grid & card options.
class WizardAreaStep extends StatelessWidget {
  final String selectedRoom;
  final ValueChanged<String> onRoomSelected;

  const WizardAreaStep({
    super.key,
    required this.selectedRoom,
    required this.onRoomSelected,
  });

  static const List<Map<String, dynamic>> _rooms = [
    {
      'name': 'Ruang Tamu',
      'icon': Icons.weekend_outlined,
      'desc': 'Area utama dengan sirkulasi baik',
    },
    {
      'name': 'Kamar Tidur',
      'icon': Icons.bed_outlined,
      'desc': 'Tanaman penyaring udara relaksasi',
    },
    {
      'name': 'Balkon',
      'icon': Icons.balcony_outlined,
      'desc': 'Pencahayaan alami & angin segar',
    },
    {
      'name': 'Taman / Teras',
      'icon': Icons.yard_outlined,
      'desc': 'Area terbuka dengan sinar melimpah',
    },
    {
      'name': 'Ruang Kerja',
      'icon': Icons.computer_outlined,
      'desc': 'Penyegar mata saat bekerja',
    },
    {
      'name': 'Dapur / Meja Makan',
      'icon': Icons.soup_kitchen_outlined,
      'desc': 'Dekat sumber air dan cahaya dapur',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lokasi Ruangan',
            style: AppTypography.displayLarge.copyWith(
              fontSize: 32,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pilih ruangan atau zona tempat tanaman ini akan diletakkan.',
            style: AppTypography.bodyRegular.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 20),

          // Room Options
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _rooms.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final room = _rooms[index];
              final name = room['name'] as String;
              final icon = room['icon'] as IconData;
              final desc = room['desc'] as String;
              final isSelected = selectedRoom == name;

              return GestureDetector(
                onTap: () => onRoomSelected(name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.pastelGreenBg
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.forest : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.forest
                              : AppColors.canvasDefault,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? Colors.white : AppColors.muted,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: AppTypography.calloutBold.copyWith(
                                color: isSelected
                                    ? AppColors.forest
                                    : AppColors.inkSoft,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              desc,
                              style: AppTypography.footnoteRegular.copyWith(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected ? AppColors.forest : AppColors.muted,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
