import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_typography.dart';
import 'package:plenty/features/plant/domain/entities/plant_entity.dart';

/// Card listing botanical growth specs of a plant.
class PlantGrowthSpecs extends StatelessWidget {
  final PlantEntity plant;

  const PlantGrowthSpecs({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildSpecRow('Tinggi Maksimal', plant.maxHeight),
          const Divider(),
          _buildSpecRow('Tingkat Pertumbuhan', plant.growthRate),
          const Divider(),
          _buildSpecRow('Siklus Tumbuh', plant.growthCycle),
          const Divider(),
          _buildSpecRow('Musim Pemangkasan', plant.pruningSeason),
          const Divider(),
          _buildSpecRow('Bunga', plant.flowerStatus),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.footnoteRegular.copyWith(
              color: AppColors.inkSoft,
            ),
          ),
          Text(
            value,
            style: AppTypography.footnoteBold.copyWith(color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}
