import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_typography.dart';
import 'package:plenty/features/plant/domain/entities/care_task_entity.dart';
import 'package:plenty/features/plant/domain/entities/plant_entity.dart';
import 'package:plenty/features/plant/presentation/home/widgets/add_new_plant_card.dart';
import 'package:plenty/features/plant/presentation/home/widgets/plant_card.dart';

/// Dashboard Tab displaying Streak, Task overview, and Plant collection grid.
class DashboardTab extends StatelessWidget {
  final String profileName;
  final int streakCount;
  final List<PlantEntity> plants;
  final List<CareTaskEntity> tasks;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final Future<void> Function() onRefresh;
  final VoidCallback onCheckTasks;
  final VoidCallback onSeeAllCatalog;
  final ValueChanged<PlantEntity> onSelectPlant;
  final VoidCallback onAddNewPlant;

  const DashboardTab({
    super.key,
    required this.profileName,
    required this.streakCount,
    required this.plants,
    required this.tasks,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onRefresh,
    required this.onCheckTasks,
    required this.onSeeAllCatalog,
    required this.onSelectPlant,
    required this.onAddNewPlant,
  });

  static const List<String> roomFilters = [
    'Semua',
    'Ruang Tamu',
    'Kamar',
    'Dapur',
    'Ruang Kerja',
  ];

  @override
  Widget build(BuildContext context) {
    final filteredPlants = selectedFilter == 'Semua'
        ? plants
        : plants.where((p) => p.specificArea == selectedFilter).toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.forest,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, $profileName',
                      style: AppTypography.title2Bold.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Semoga harimu seindah kebunmu.',
                      style: AppTypography.footnoteRegular.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.forest.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                  child: const Icon(Icons.person, color: AppColors.forest),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Streak & Dynamic Task Widget Row
            Row(
              children: [
                // Streak Card
                Expanded(
                  child: Container(
                    height: 110,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.forest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.forest.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.amber,
                          size: 28,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$streakCount',
                              style: AppTypography.largeTitleBold.copyWith(
                                color: Colors.white,
                                fontSize: 24,
                                height: 1,
                              ),
                            ),
                            Text(
                              'Hari Streak',
                              style: AppTypography.footnoteRegular.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Tasks Card
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 110,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TUGAS HARI INI',
                              style: AppTypography.footnoteBold.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                            const Icon(
                              Icons.assignment_outlined,
                              color: AppColors.forest,
                              size: 18,
                            ),
                          ],
                        ),
                        Text(
                          tasks.isEmpty
                              ? 'Semua tanaman sudah terawat!'
                              : '${tasks.length} tugas butuh perhatianmu.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.footnoteBold.copyWith(
                            color: AppColors.inkSoft,
                          ),
                        ),
                        InkWell(
                          onTap: onCheckTasks,
                          child: Row(
                            children: [
                              Text(
                                'Cek Sekarang',
                                style: AppTypography.footnoteBold.copyWith(
                                  color: AppColors.forest,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward,
                                color: AppColors.forest,
                                size: 12,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Koleksi Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Koleksi',
                  style: AppTypography.title2Bold.copyWith(
                    color: AppColors.ink,
                  ),
                ),
                TextButton(
                  onPressed: onSeeAllCatalog,
                  child: Row(
                    children: [
                      Text(
                        'Lihat Semua',
                        style: AppTypography.calloutBold.copyWith(
                          color: AppColors.forest,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.forest,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Horizontal Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: roomFilters.map((room) {
                  final isSelected = selectedFilter == room;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(room),
                      selected: isSelected,
                      onSelected: (_) => onFilterChanged(room),
                      selectedColor: AppColors.forest,
                      backgroundColor: AppColors.surface,
                      labelStyle: AppTypography.footnoteBold.copyWith(
                        color: isSelected ? Colors.white : AppColors.inkSoft,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.forest : AppColors.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Grid of Plants & Add New Card
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredPlants.length + 1,
              itemBuilder: (context, index) {
                if (index == filteredPlants.length) {
                  return AddNewPlantCard(onTap: onAddNewPlant);
                }
                final plant = filteredPlants[index];
                return PlantCard(
                  plant: plant,
                  onTap: () => onSelectPlant(plant),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
