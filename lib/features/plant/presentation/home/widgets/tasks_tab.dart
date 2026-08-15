import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_typography.dart';
import 'package:plenty/features/plant/domain/entities/care_task_entity.dart';
import 'package:plenty/features/plant/presentation/home/widgets/task_card.dart';

/// Tasks tab listing outstanding daily care actions.
class TasksTab extends StatelessWidget {
  final List<CareTaskEntity> tasks;
  final ValueChanged<CareTaskEntity> onCompleteTask;

  const TasksTab({
    super.key,
    required this.tasks,
    required this.onCompleteTask,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tugas Hari Ini',
            style: AppTypography.title2Bold.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            'Selesaikan tugas di bawah ini untuk menjaga kebugaran tanamanmu.',
            style: AppTypography.footnoteRegular.copyWith(
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.emerald,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Kerja Bagus!',
                          style: AppTypography.headline.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Semua tugas hari ini telah diselesaikan.',
                          style: AppTypography.footnoteRegular.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TaskCard(
                        task: task,
                        onComplete: () => onCompleteTask(task),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
