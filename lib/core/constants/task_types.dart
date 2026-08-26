import 'package:flutter/material.dart';

/// Task types for daily plant care routines.
enum TaskType {
  siram(
    'siram',
    'Siram Tanaman',
    'Siram',
    'Penyiraman',
    Icons.water_drop,
    Colors.blue,
  ),
  bersih(
    'bersih',
    'Bersihkan Tanaman',
    'Bersihkan',
    'Kebersihan',
    Icons.cleaning_services,
    Colors.orange,
  ),
  monitor(
    'monitor',
    'Log Harian Tanaman',
    'Catat',
    'Log Harian',
    Icons.straighten,
    Colors.green,
  );

  final String id;
  final String title;
  final String action;
  final String label;
  final IconData icon;
  final Color color;

  const TaskType(
    this.id,
    this.title,
    this.action,
    this.label,
    this.icon,
    this.color,
  );

  String get dbString => id;

  static TaskType fromId(String id) {
    return switch (id) {
      'siram' => TaskType.siram,
      'bersih' => TaskType.bersih,
      'monitor' => TaskType.monitor,
      _ => TaskType.siram,
    };
  }

  static TaskType fromDbString(String str) => fromId(str);
}
