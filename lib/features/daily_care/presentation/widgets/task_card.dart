import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/features/daily_care/domain/models/care_task_model.dart';

class TaskCard extends StatelessWidget {
  final CareTaskModel task;
  final VoidCallback onAction;
  final bool? isCompleted;

  const TaskCard({
    super.key,
    required this.task,
    required this.onAction,
    this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final done = isCompleted ?? task.isCompleted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: done ? AppColors.surface.withValues(alpha: 0.8) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done ? AppColors.border.withValues(alpha: 0.6) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: done
                  ? AppColors.pastelGreenBg.withValues(alpha: 0.6)
                  : task.type.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              task.type.icon,
              color: done ? AppColors.muted : task.type.color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.type.title,
                  style: AppTypography.calloutBold.copyWith(
                    color: done ? AppColors.muted : AppColors.inkSoft,
                    decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                    decorationColor: AppColors.muted,
                    decorationThickness: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.plant.nickname,
                  style: AppTypography.footnoteRegular.copyWith(
                    color: AppColors.muted,
                    decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                    decorationColor: AppColors.muted,
                    decorationThickness: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (done)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.check_circle,
                color: AppColors.forest,
                size: 26,
              ),
            )
          else
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: task.type.color,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                task.type.action,
                style: AppTypography.caption1Bold.copyWith(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
