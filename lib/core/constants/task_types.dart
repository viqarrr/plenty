import 'package:flutter/material.dart';

/// Task types for daily plant care routines (v2: siram, bersih_bersih, monitor_tinggi).
/// Note: 'cek_hama' is completely removed from the code logic.
enum TaskType {
  siram('siram', 'Siram Tanaman', 'Siram', 'Penyiraman', Icons.water_drop, Colors.blue),
  bersihBersih('bersih_bersih', 'Bersihkan Tanaman', 'Bersihkan', 'Kebersihan', Icons.cleaning_services, Colors.orange),
  monitorTinggi('monitor_tinggi', 'Log Harian Tanaman', 'Catat', 'Log Harian', Icons.straighten, Colors.green);

  final String id;
  final String title;
  final String action;
  final String label;
  final IconData icon;
  final Color color;

  const TaskType(this.id, this.title, this.action, this.label, this.icon, this.color);

  String get dbString => id;

  static TaskType fromId(String id) {
    return switch (id) {
      'siram' => TaskType.siram,
      'bersih_bersih' => TaskType.bersihBersih,
      'monitor_tinggi' => TaskType.monitorTinggi,
      _ => TaskType.siram,
    };
  }

  static TaskType fromDbString(String str) => fromId(str);
}
