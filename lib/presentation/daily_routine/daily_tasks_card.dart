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
                    'Semua Tugas Hari Ini Selesai',
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
        for (int i = 0; i < tasks.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          TaskCard(
            task: tasks[i],
            onAction: () {
              if (tasks[i].type == TaskType.monitorTinggi) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => MonitorTinggiInputSheet(
                    plant: tasks[i].plant,
                    onSubmit: (heightCm, note, photoPath) {
                      onCompleteTask(
                        tasks[i],
                        heightCm: heightCm,
                        note: note,
                        photoPath: photoPath,
                      );
                    },
                  ),
                );
              } else {
                onCompleteTask(tasks[i]);
              }
            },
          ),
        ],
      ],
    );
  }
}
