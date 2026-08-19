import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';

/// Clean and responsive step indicator showing current step progress in custom plant wizard.
class WizardStepProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String? stepTitle;

  const WizardStepProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.stepTitle,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentStep + 1) / totalSteps;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.borderSubtle,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.forest),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
