import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/features/daily_care/domain/models/daily_care_state.dart';
import 'package:plenty/features/daily_care/presentation/daily_care_controller.dart';
import 'package:plenty/features/daily_care/presentation/screens/care_history_screen.dart';
import 'package:plenty/features/daily_care/presentation/widgets/monitor_tinggi_input_sheet.dart';

/// Main screen for Daily Care Routine implementing consistent Plenty design language.
class DailyCareScreen extends StatefulWidget {
  final DailyCareController? controller;

  const DailyCareScreen({super.key, this.controller});

  @override
  State<DailyCareScreen> createState() => _DailyCareScreenState();
}

class _DailyCareScreenState extends State<DailyCareScreen> {
  late final DailyCareController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? DailyCareController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  String _formatCurrentDate() {
    final now = DateTime.now();
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  void _openHeightInputSheet(
    BuildContext context,
    DailyHeightLogItem item,
    DailyCareController controller,
  ) {
    final isEdit = item.isCompletedToday;
    final initialHeight = isEdit && item.loggedHeightToday != null
        ? item.loggedHeightToday!
        : item.lastRecordedHeight;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MonitorTinggiInputSheet(
        plant: item.plant,
        lastRecordedHeight: initialHeight,
        isPhotoRequired: item.isPhotoDue,
        isEditMode: isEdit,
        initialNote: item.loggedNoteToday,
        initialPhotoPath: item.loggedPhotoPathToday,
        onSubmit: (heightCm, note, photoPath) {
          if (isEdit) {
            controller.updateHeightTask(
              plant: item.plant,
              heightCm: heightCm,
              note: note,
              photoPath: photoPath,
            );
          } else {
            controller.completeHeightTask(
              plant: item.plant,
              heightCm: heightCm,
              note: note,
              photoPath: photoPath,
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;

        return Scaffold(
          backgroundColor: AppColors.canvasDefault,
          body: state.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.forest),
                )
              : RefreshIndicator(
                  onRefresh: _controller.loadTodayCare,
                  color: AppColors.forest,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tugas Hari Ini',
                                          style: AppTypography.displayLarge
                                              .copyWith(
                                                color: AppColors.inkSoft,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _formatCurrentDate(),
                                          style: AppTypography.footnoteRegular
                                              .copyWith(
                                                color: AppColors.muted,
                                                fontSize: 16,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const CareHistoryScreen(),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.history,
                                              color: AppColors.forest,
                                              size: 32,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              _buildSectionHeader(
                                title: 'Log Pertumbuhan Harian',
                              ),
                              const SizedBox(height: 12),
                              if (state.heightLogs.isEmpty)
                                _buildEmptyNote(
                                  'Belum ada tanaman yang diadopsi untuk dicatat hari ini.',
                                )
                              else
                                ...state.heightLogs.map(
                                  (item) => _buildMandatoryHeightCard(
                                    context,
                                    item,
                                    _controller,
                                  ),
                                ),
                              const SizedBox(height: 24),
                              _buildSectionHeader(title: 'Jadwal Rutin'),
                              const SizedBox(height: 12),
                              if (state.dueSchedules.isEmpty)
                                _buildEmptyNote(
                                  'Tidak ada tugas tambahan yang dijadwalkan hari ini',
                                )
                              else
                                ...state.dueSchedules.map(
                                  (item) =>
                                      _buildDueScheduleCard(item, _controller),
                                ),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          bottomSheet: state.isLoading || state.hasNoTasksScheduled
              ? null
              : Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              state.isAllCompleted
                                  ? 'Semua tugas hari ini selesai 🎉'
                                  : '${state.completedTasksCount} dari ${state.totalTasksCount} tugas selesai',
                              style: AppTypography.caption1Bold.copyWith(
                                color: AppColors.forest,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${(state.progressRatio * 100).toInt()}%',
                              style: AppTypography.caption1Bold.copyWith(
                                color: AppColors.forest,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: state.progressRatio,
                            minHeight: 6,
                            backgroundColor: AppColors.borderLight,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.forest,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSectionHeader({required String title}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.title2Bold.copyWith(
            color: AppColors.inkSoft,
            fontSize: 17,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyNote(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        style: AppTypography.bodyRegular.copyWith(
          color: AppColors.muted,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildMandatoryHeightCard(
    BuildContext context,
    DailyHeightLogItem item,
    DailyCareController controller,
  ) {
    final isDone = item.isCompletedToday;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone ? AppColors.surface.withValues(alpha: 0.8) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? AppColors.border.withValues(alpha: 0.6) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.pastelGreenBg.withValues(alpha: 0.6)
                  : AppColors.pastelGreenBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.isPhotoDue && !isDone
                  ? Icons.camera_alt_outlined
                  : Icons.straighten,
              color: isDone ? AppColors.muted : AppColors.forest,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.plant.nickname,
                        style: AppTypography.calloutBold.copyWith(
                          color: isDone ? AppColors.muted : AppColors.inkSoft,
                          fontSize: 15,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          decorationColor: AppColors.muted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.isPhotoDue && !isDone) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.pastelGreenBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.forest.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          'Siklus Foto',
                          style: AppTypography.caption1Bold.copyWith(
                            color: AppColors.forest,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isDone
                      ? 'Tercatat: ${item.loggedHeightToday?.toStringAsFixed(1) ?? item.lastRecordedHeight.toStringAsFixed(1)} cm'
                      : 'Tinggi terakhir: ${item.lastRecordedHeight.toStringAsFixed(1)} cm',
                  style: AppTypography.caption1Regular.copyWith(
                    color: isDone
                        ? AppColors.muted
                        : AppColors.muted,
                    fontSize: 13,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (isDone)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.forest,
                  size: 24,
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () =>
                      _openHeightInputSheet(context, item, controller),
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.muted,
                    size: 20,
                  ),
                  tooltip: 'Koreksi Log',
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            )
          else
            ElevatedButton(
              onPressed: () => _openHeightInputSheet(context, item, controller),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                'Catat Log',
                style: AppTypography.caption1Bold.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDueScheduleCard(
    DueScheduleItem item,
    DailyCareController controller,
  ) {
    final icon = item.taskType == 'siram'
        ? Icons.water_drop_outlined
        : Icons.cleaning_services_outlined;
    final isDone = item.isCompletedToday;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone ? AppColors.surface.withValues(alpha: 0.8) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? AppColors.border.withValues(alpha: 0.6) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.pastelGreenBg.withValues(alpha: 0.6)
                  : AppColors.pastelGreenBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDone ? AppColors.muted : AppColors.forest,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.title} · ${item.plant.nickname}',
                  style: AppTypography.calloutBold.copyWith(
                    color: isDone ? AppColors.muted : AppColors.inkSoft,
                    fontSize: 15,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: AppTypography.caption1Regular.copyWith(
                    color: AppColors.muted,
                    fontSize: 13,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (isDone)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.check_circle,
                color: AppColors.forest,
                size: 26,
              ),
            )
          else
            IconButton(
              onPressed: () => controller.completeCyclicTask(item),
              icon: const Icon(
                Icons.radio_button_unchecked,
                color: AppColors.forest,
                size: 26,
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}
