import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/features/garden/domain/models/growth_log_model.dart';

/// FlChart-based growth height curve widget for PlantDetailsScreen.
class GrowthHeightChart extends StatelessWidget {
  final List<GrowthLogModel> growthLogs;

  const GrowthHeightChart({super.key, required this.growthLogs});

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  String _formatMonthYear(DateTime dt, bool hasMultipleInSameMonth) {
    final m = _months[dt.month - 1];
    final y = (dt.year % 100).toString().padLeft(2, '0');
    if (hasMultipleInSameMonth) {
      return '${dt.day} $m';
    }
    return "$m '$y";
  }

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
    double minHeight = double.infinity;
    double maxHeight = -double.infinity;

    // Check if there are multiple logs in the same month/year to format dates clearly
    final monthYearSet = <String>{};
    bool hasMultipleInSameMonth = false;
    for (final log in growthLogs) {
      final key = '${log.loggedAt.year}_${log.loggedAt.month}';
      if (monthYearSet.contains(key)) {
        hasMultipleInSameMonth = true;
      }
      monthYearSet.add(key);

      final h = log.heightCm ?? 0.0;
      if (h < minHeight) minHeight = h;
      if (h > maxHeight) maxHeight = h;
    }

    for (var i = 0; i < growthLogs.length; i++) {
      spots.add(FlSpot(i.toDouble(), growthLogs[i].heightCm ?? 0.0));
    }

    if (minHeight == double.infinity) minHeight = 0.0;
    if (maxHeight == -double.infinity) maxHeight = 100.0;

    final minY = (minHeight - 5).clamp(0.0, double.infinity);
    final maxY = (maxHeight + 10).ceilToDouble();

    return Container(
      height: 220,
      padding: const EdgeInsets.only(top: 24, right: 24, left: 12, bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (growthLogs.length > 1 ? growthLogs.length - 1 : 1).toDouble(),
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY > 0)
                ? ((maxY - minY) / 4).clamp(5.0, 50.0)
                : 10,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.border.withValues(alpha: 0.5),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()} cm',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 &&
                      index < growthLogs.length &&
                      (value - index).abs() < 0.01) {
                    final dt = growthLogs[index].loggedAt;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _formatMonthYear(dt, hasMultipleInSameMonth),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => AppColors.inkSoft,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  if (index >= 0 && index < growthLogs.length) {
                    final log = growthLogs[index];
                    final dt = log.loggedAt;
                    final m = _months[dt.month - 1];
                    return LineTooltipItem(
                      '${spot.y.toStringAsFixed(1)} cm\n${dt.day} $m ${dt.year}',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)} cm',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: growthLogs.length > 2,
              color: AppColors.forest,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.forest,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.pastelGreenBg.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
