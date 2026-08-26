import 'package:flutter/material.dart';
import 'package:plenty/features/profile/domain/models/badge_item.dart';

/// Presentation extension providing visual Flutter widgets and colors from BadgeItem domain model.
extension BadgeItemUIExtension on BadgeItem {
  /// Resolves Flutter IconData from string icon name.
  IconData get icon {
    switch (iconName.toLowerCase().trim()) {
      case 'sprout':
      case 'eco':
        return Icons.eco_rounded;
      case 'droplets':
      case 'water_drop':
      case 'water_drop_rounded':
        return Icons.water_drop_rounded;
      case 'hourglass':
      case 'hourglass_top_rounded':
        return Icons.hourglass_top_rounded;
      case 'trees':
      case 'park':
      case 'park_rounded':
        return Icons.park_rounded;
      case 'activity':
      case 'monitor_heart':
      case 'monitor_heart_rounded':
        return Icons.monitor_heart_rounded;
      case 'sun':
      case 'wb_sunny':
      case 'wb_sunny_rounded':
        return Icons.wb_sunny_rounded;
      default:
        return Icons.military_tech_rounded;
    }
  }

  Color get bgColor => const Color(0xFFEBF7F1);

  Color get accentColor => const Color(0xFF2D6A4F);
}
