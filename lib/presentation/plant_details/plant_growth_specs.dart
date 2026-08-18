import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/data/models/plant_model.dart';

class PlantGrowthSpecs extends StatelessWidget {
  final PlantModel plant;

  const PlantGrowthSpecs({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kebutuhan Perawatan',
            style: AppTypography.title2Bold.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildSpecRow(
            icon: Icons.water_drop_outlined,
            title: 'Interval Penyiraman',
            value: 'Setiap ${plant.wateringSchedule} hari sekali',
            color: Colors.blue,
          ),
          const Divider(color: AppColors.borderSubtle, height: 24),
          _buildSpecRow(
            icon: Icons.wb_sunny_outlined,
            title: 'Kebutuhan Cahaya',
            value: plant.lightIntensity,
            color: Colors.orange,
          ),
          const Divider(color: AppColors.borderSubtle, height: 24),
          _buildSpecRow(
            icon: Icons.thermostat_outlined,
            title: 'Suhu Ideal',
            value: plant.temperatureRange,
            color: AppColors.forest,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.caption1Regular.copyWith(
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.calloutBold.copyWith(
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
