import 'dart:io';
import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/data/models/growth_log_model.dart';

/// Vertical Stepper Timeline widget displaying chronological photo & height progress of a plant.
class PhotoTimelineStepper extends StatelessWidget {
  final List<GrowthLogModel> logs;
  final void Function(GrowthLogModel log)? onEditLog;

  const PhotoTimelineStepper({
    super.key,
    required this.logs,
    this.onEditLog,
  });

  String _formatDate(DateTime dt) {
    const months = [
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 40,
              color: AppColors.muted,
            ),
            const SizedBox(height: 10),
            Text(
              'Belum ada linimasa foto',
              style: AppTypography.calloutBold.copyWith(
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Foto yang kamu ambil saat mencatat tinggi tanaman harian akan muncul di sini sebagai jurnal pertumbuhan visual.',
              textAlign: TextAlign.center,
              style: AppTypography.footnoteRegular.copyWith(
                color: AppColors.muted,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final isLast = index == logs.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stepper Line & Node Indicator
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: index == 0
                          ? AppColors.forest
                          : AppColors.pastelGreenBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.forest,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        index == 0 ? Icons.eco : Icons.photo_camera,
                        size: 14,
                        color: index == 0 ? Colors.white : AppColors.forest,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppColors.forest.withValues(alpha: 0.3),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Content Card
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(bottom: isLast ? 0 : 20.0),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date & Height Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.pastelGreenBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatDate(log.loggedAt),
                              style: AppTypography.caption1Bold.copyWith(
                                color: AppColors.forest,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              if (log.heightCm != null) ...[
                                const Icon(
                                  Icons.straighten,
                                  size: 16,
                                  color: AppColors.forest,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${log.heightCm!.toStringAsFixed(1)} cm',
                                  style: AppTypography.calloutBold.copyWith(
                                    color: AppColors.inkSoft,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              if (onEditLog != null) ...[
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => onEditLog!(log),
                                  borderRadius: BorderRadius.circular(6),
                                  child: const Padding(
                                    padding: EdgeInsets.all(2.0),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),

                      // Optional Photo Preview (only if valid photo exists, no dummy placeholder)
                      Builder(
                        builder: (context) {
                          final photoWidget = _buildPhotoImage(log.photoPath);
                          if (photoWidget == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: photoWidget,
                            ),
                          );
                        },
                      ),

                      // Optional Note
                      if (log.note != null && log.note!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '"${log.note}"',
                          style: AppTypography.footnoteRegular.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget? _buildPhotoImage(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final trimmed = path.trim();

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    }

    if (trimmed.startsWith('assets/')) {
      return Image.asset(
        trimmed,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    }

    final file = File(trimmed);
    if (file.existsSync()) {
      return Image.file(
        file,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    }

    return null;
  }
}
