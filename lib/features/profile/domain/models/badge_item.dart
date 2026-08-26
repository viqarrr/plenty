import 'package:flutter/foundation.dart';

/// Pure domain entity model representing a collectible badge or achievement.
@immutable
class BadgeItem {
  final String id;
  final String title;
  final String desc;
  final String iconName;
  final bool isUnlocked;
  final String? unlockedDate;
  final int level;
  final int progress;
  final int total;
  final String bgColorHex;
  final String accentColorHex;
  final String tierName;

  const BadgeItem({
    required this.id,
    required this.title,
    required this.desc,
    this.iconName = 'sprout',
    required this.isUnlocked,
    this.unlockedDate,
    required this.level,
    required this.progress,
    required this.total,
    this.bgColorHex = '#EBF7F1',
    this.accentColorHex = '#2D6A4F',
    this.tierName = '',
  });

  BadgeItem copyWith({
    String? id,
    String? title,
    String? desc,
    String? iconName,
    bool? isUnlocked,
    String? unlockedDate,
    int? level,
    int? progress,
    int? total,
    String? bgColorHex,
    String? accentColorHex,
    String? tierName,
  }) {
    return BadgeItem(
      id: id ?? this.id,
      title: title ?? this.title,
      desc: desc ?? this.desc,
      iconName: iconName ?? this.iconName,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedDate: unlockedDate ?? this.unlockedDate,
      level: level ?? this.level,
      progress: progress ?? this.progress,
      total: total ?? this.total,
      bgColorHex: bgColorHex ?? this.bgColorHex,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      tierName: tierName ?? this.tierName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BadgeItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          isUnlocked == other.isUnlocked &&
          progress == other.progress;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ isUnlocked.hashCode ^ progress.hashCode;
}
