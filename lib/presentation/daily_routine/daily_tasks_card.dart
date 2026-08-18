import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/data/models/care_task_model.dart';
import 'package:plenty/presentation/daily_routine/monitor_tinggi_input_sheet.dart';
import 'package:plenty/presentation/daily_routine/task_card.dart';

class DailyTasksCard extends StatelessWidget {
  final List<CareTaskModel> tasks;
  final void Function(
    CareTaskModel task, {
    double? heightCm,
    String? note,
    String? photoPath,
  })
  onCompleteTask;

  const DailyTasksCard({
    super.key,
    required this.tasks,
    required this.onCompleteTask,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.pastelGreenBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.forest.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.task_alt, color: AppColors.forest, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Semua Tugas Hari Ini Selesai! 🎉',
                    style: AppTypography.calloutBold.copyWith(
                      color: AppColors.forest,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tanamanmu bahagia dan sehat. Kembali lagi besok ya!',
                    style: AppTypography.footnoteRegular.copyWith(
                      color: AppColors.forest,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rutinitas Perawatan Hari Ini',
              style: AppTypography.title2Bold.copyWith(fontSize: 18),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.forest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${tasks.length} Tersisa',
                style: AppTypography.caption1Bold.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final task = tasks[index];
            return TaskCard(
              task: task,
              onAction: () {
                if (task.type == TaskType.monitorTinggi) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => MonitorTinggiInputSheet(
                      plant: task.plant,
                      onSubmit: (heightCm, note, photoPath) {
                        onCompleteTask(
                          task,
                          heightCm: heightCm,
                          note: note,
                          photoPath: photoPath,
                        );
                      },
                    ),
                  );
                } else {
                  onCompleteTask(task);
                }
              },
            );
          },
        ),
      ],
    );
  }
}
