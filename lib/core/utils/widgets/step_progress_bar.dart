import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';

/// Reusable Multi-Step Segmented Progress Bar indicator.
class StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Color activeColor;
  final Color inactiveColor;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.activeColor = AppColors.forest,
    this.inactiveColor = AppColors.border,
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
              color: isActive ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
