import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_typography.dart';
import 'package:plenty/features/plant/domain/entities/care_task_entity.dart';

/// Single Care Task Card with completion button.
class TaskCard extends StatelessWidget {
  final CareTaskEntity task;
  final VoidCallback onComplete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: task.type.color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            task.type.icon,
            color: task.type.color,
            size: 24,
          ),
        ),
        title: Text(
          '${task.type.action} ${task.plant.name}',
          style: AppTypography.headline.copyWith(fontSize: 16),
        ),
        subtitle: Text(
          task.description,
          style: AppTypography.footnoteRegular.copyWith(
            color: AppColors.muted,
          ),
        ),
        trailing: ElevatedButton(
          onPressed: onComplete,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.forest,
            foregroundColor: Colors.white,
            minimumSize: const Size(60, 36),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: const Text('Selesai'),
        ),
      ),
    );
  }
}
