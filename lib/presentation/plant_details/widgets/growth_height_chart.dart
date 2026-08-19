import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/data/models/growth_log_model.dart';

/// FlChart-based growth height curve widget for PlantDetailsScreen.
class GrowthHeightChart extends StatelessWidget {
  final List<GrowthLogModel> growthLogs;

  const GrowthHeightChart({super.key, required this.growthLogs});

  @override
  Widget build(BuildContext context) {
    if (growthLogs.isEmpty) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'Belum ada riwayat pengukuran tinggi',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < growthLogs.length; i++) {
      spots.add(FlSpot(i.toDouble(), growthLogs[i].heightCm ?? 0.0));
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.only(top: 20, right: 20, left: 10, bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.forest,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.pastelGreenBg.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
