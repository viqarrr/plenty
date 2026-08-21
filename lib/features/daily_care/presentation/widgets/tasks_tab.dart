import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/features/daily_care/domain/models/care_task_model.dart';
import 'package:plenty/features/daily_care/presentation/widgets/monitor_tinggi_input_sheet.dart';
import 'package:plenty/features/daily_care/presentation/widgets/task_card.dart';

typedef TaskCompletionCallback =
    void Function(
      CareTaskModel task, {
      double? heightCm,
      String? note,
      String? photoPath,
    });

class TasksTab extends StatelessWidget {
  final List<CareTaskModel> tasks;
  final TaskCompletionCallback onCompleteTask;

  const TasksTab({
    super.key,
    required this.tasks,
    required this.onCompleteTask,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
          child: Text(
            'Daftar Tugas Perawatan',
            style: AppTypography.title2Bold.copyWith(color: AppColors.inkSoft),
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: AppColors.forest,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Semua Tugas Selesai!',
                        style: AppTypography.title2Bold.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tidak ada perawatan yang tertunda.',
                        style: AppTypography.footnoteRegular.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 12.0,
                  ),
                  itemCount: tasks.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
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
        ),
      ],
    );
  }
}
