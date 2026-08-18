import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/presentation/add_plant/add_plant_flow_controller.dart';
import 'package:plenty/presentation/add_plant/add_plant_flow_screen.dart';
import 'package:plenty/presentation/daily_routine/daily_tasks_card.dart';
import 'package:plenty/presentation/home/home_controller.dart';
import 'package:plenty/presentation/home/plant_collection_grid.dart';

class HomePopulatedScreen extends ConsumerWidget {
  final Future<void> Function() onRefresh;

  const HomePopulatedScreen({super.key, required this.onRefresh});

  static const List<String> roomFilters = [
    'Semua',
    'Ruang Tamu',
    'Kamar',
    'Dapur',
    'Ruang Kerja',
    'Balkon',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.canvasDefault,
      body: RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.forest,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, ${state.profileName} 👋',
                        style: AppTypography.displayLarge.copyWith(
                          fontSize: 22,
                          color: AppColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Waktunya merawat tanamanmu hari ini!',
                        style: AppTypography.footnoteRegular.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.pastelYellowBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.pastelYellowText.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${state.streakCount} Hari',
                          style: AppTypography.caption1Bold.copyWith(
                            color: AppColors.pastelYellowText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              DailyTasksCard(
                tasks: state.dailyTasks,
                onCompleteTask: (task, {heightCm, note, photoPath}) async {
                  await controller.completeTask(
                    task: task,
                    heightCm: heightCm,
                    note: note,
                    photoPath: photoPath,
                  );
                },
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Koleksi Tanaman',
                    style: AppTypography.title2Bold.copyWith(fontSize: 18),
                  ),
                  Text(
                    '${state.filteredPlants.length} Tanaman',
                    style: AppTypography.caption1Regular.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: roomFilters.map((filter) {
                    final isSelected = state.selectedRoomFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (_) => controller.setRoomFilter(filter),
                        selectedColor: AppColors.forest,
                        backgroundColor: AppColors.surface,
                        labelStyle: AppTypography.footnoteBold.copyWith(
                          color: isSelected ? Colors.white : AppColors.inkSoft,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.forest
                              : AppColors.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              PlantCollectionGrid(plants: state.filteredPlants),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(
            const AddPlantFlowScreen(entryPoint: AddPlantEntryPoint.fabHome),
          );
        },
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Tanaman'),
      ),
    );
  }
}
