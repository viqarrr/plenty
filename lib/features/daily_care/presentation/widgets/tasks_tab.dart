import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TUGAS HARIAN',
                style: AppTypography.caption2Bold.copyWith(
                  color: AppColors.muted,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.pastelGreenBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${tasks.length} Tersisa',
                  style: AppTypography.caption1Bold.copyWith(
                    color: AppColors.forest,
                  ),
                ),
              ),
            ],
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
                        color: AppColors.forest,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Semua tugas hari ini selesai!',
                        style: AppTypography.calloutBold.copyWith(
                          color: AppColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tanaman Anda sudah mendapatkan perawatan terbaik.',
                        style: AppTypography.footnoteRegular.copyWith(
                          color: AppColors.muted,
                        ),
                        textAlign: TextAlign.center,
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
                        if (task.type == TaskType.monitor) {
                          context.showAppBottomSheet(
                            MonitorTinggiInputSheet(
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
