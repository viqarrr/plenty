import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/features/garden/domain/models/streak_model.dart';

extension UserStreakModelUIExtension on UserStreakModel {
  /// Returns corresponding tier display color.
  Color get tierColor {
    return switch (currentTier) {
      7 => AppColors.tierMythicText,
      6 => AppColors.tierLegendText,
      5 => AppColors.tierEpicText,
      4 => AppColors.tierSpecialText,
      3 => AppColors.tierEliteText,
      2 => AppColors.pastelGreenText,
      _ => AppColors.tierNormalText,
    };
  }
}
