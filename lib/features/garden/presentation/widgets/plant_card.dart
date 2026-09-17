import 'dart:io';

import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';

class PlantCard extends StatelessWidget {
  final PlantModel plant;
  final VoidCallback onTap;

  const PlantCard({super.key, required this.plant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(color: AppColors.pastelGreenBg),
                      child: _buildPlantImage(),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.forest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Lv.${plant.level}',
                        style: AppTypography.caption1Bold.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title2Bold.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plant.scientificName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption1Regular.copyWith(
                      color: AppColors.muted,
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantImage() {
    var photo = plant.coverPhotoPath?.trim();
    if (photo != null && photo.isNotEmpty) {
      if (photo.startsWith('gs://')) {
        final uri = Uri.tryParse(photo);
        if (uri != null && uri.host.isNotEmpty) {
          final bucket = uri.host;
          final path =
              uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
          photo =
              'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(path)}?alt=media';
        }
      }

      if (photo.startsWith('http://') || photo.startsWith('https://')) {
        return Image.network(
          photo,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) => _buildFallbackIcon(),
        );
      } else if (photo.startsWith('assets/')) {
        return Image.asset(
          photo,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) => _buildFallbackIcon(),
        );
      } else {
        final file = File(photo);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, _, _) => _buildFallbackIcon(),
          );
        }
      }
    }
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Center(
      child: Icon(
        Icons.local_florist,
        color: AppColors.forest.withValues(alpha: 0.8),
        size: 48,
      ),
    );
  }
}
