import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';

/// 5-segment progress bar for custom plant addition wizard.
class WizardStepProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const WizardStepProgress({
    super.key,
    required this.currentStep,
    this.totalSteps = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index <= currentStep;
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isActive ? AppColors.forest : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
