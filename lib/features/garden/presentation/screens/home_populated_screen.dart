import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/features/daily_care/presentation/screens/daily_care_screen.dart';
import 'package:plenty/features/garden/presentation/controllers/home_controller.dart';
import 'package:plenty/features/garden/presentation/widgets/plant_collection_grid.dart';

class HomePopulatedScreen extends StatelessWidget {
  final HomeState? state;
  final HomeController? controller;
  final Future<void> Function() onRefresh;
  final VoidCallback? onNavigateToDailyCare;

  const HomePopulatedScreen({
    super.key,
    this.state,
    this.controller,
    required this.onRefresh,
    this.onNavigateToDailyCare,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveState = state ?? controller?.state ?? const HomeState();
    final effectiveController = controller;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.forest,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, ${effectiveState.profileName}',
                        style: AppTypography.displayLarge.copyWith(
                          fontSize: 32,
                          color: AppColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Waktunya merawat tanamanmu hari ini!',
                        style: AppTypography.footnoteRegular.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _DualCardOverviewBanner(
                    state: effectiveState,
                    onNavigateToDailyCare: onNavigateToDailyCare,
                  ),
                  const SizedBox(height: 28),
                  Text('Koleksi Saya', style: AppTypography.title2Bold),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: effectiveState.availableRoomFilters.map((filter) {
                        final isSelected =
                            effectiveState.selectedRoomFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (_) {
                              effectiveController?.setRoomFilter(filter);
                            },
                            selectedColor: AppColors.forest,
                            backgroundColor: AppColors.surface,
                            labelStyle: AppTypography.footnoteBold.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.inkSoft,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.forest
                                  : AppColors.border,
                              width: 0,
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: PlantCollectionGrid(
              plants: effectiveState.filteredPlants,
              controller: effectiveController,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

/// Horizontal dual-card banner containing the Streak Card (left) and Today's Tasks Overview Card (right).
class _DualCardOverviewBanner extends StatelessWidget {
  final HomeState state;
  final VoidCallback? onNavigateToDailyCare;

  const _DualCardOverviewBanner({
    required this.state,
    this.onNavigateToDailyCare,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 5, child: _StreakCard(streakCount: state.streakCount)),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: _TodayTasksOverviewCard(
              tasksCount: state.dailyTasks.length,
              plantsCount: state.userPlants.length,
              onNavigateToDailyCare: onNavigateToDailyCare,
            ),
          ),
        ],
      ),
    );
  }
}

/// Left Card displaying current streak with watermark flame graphic.
class _StreakCard extends StatelessWidget {
  final int streakCount;

  const _StreakCard({required this.streakCount});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 144,
        decoration: const BoxDecoration(
          color: Color(0xFFF2A33A),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              bottom: -12,
              child: Icon(
                Icons.local_fire_department_rounded,
                size: 78,
                color: Colors.white.withValues(alpha: 0.20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streakCount',
                    style: AppTypography.displayLarge.copyWith(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hari Konsisten',
                    style: AppTypography.caption1Bold.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 13,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Right Card displaying task count overview and direct checklist navigation button.
class _TodayTasksOverviewCard extends StatelessWidget {
  final int tasksCount;
  final int plantsCount;
  final VoidCallback? onNavigateToDailyCare;

  const _TodayTasksOverviewCard({
    required this.tasksCount,
    this.plantsCount = 1,
    this.onNavigateToDailyCare,
  });

  @override
  Widget build(BuildContext context) {
    final titleText = plantsCount == 0
        ? 'Tidak ada tugas hari ini'
        : (tasksCount > 0
            ? '$tasksCount tanaman butuh perhatianmu hari ini'
            : 'Semua tugas hari ini selesai 🎉');

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 144,
        decoration: const BoxDecoration(color: AppColors.forest),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                Icons.eco_rounded,
                size: 76,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    titleText,
                    style: AppTypography.calloutBold.copyWith(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (onNavigateToDailyCare != null) {
                          onNavigateToDailyCare!();
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DailyCareScreen(),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Periksa Sekarang',
                              style: AppTypography.caption1Bold.copyWith(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
