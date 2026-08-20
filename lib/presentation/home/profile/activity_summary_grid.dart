import 'package:flutter/material.dart';
import 'package:plenty/core/theme/app_typography.dart';

/// "RINGKASAN AKTIVITAS" 2×2 colorful stat cards with clipped
/// watermark icons in the bottom-right corner, backed by real SQLite data.
class ActivitySummaryGrid extends StatelessWidget {
  final int streakCount;
  final int totalPlants;
  final int totalXp;
  final int badgeCount;

  const ActivitySummaryGrid({
    super.key,
    required this.streakCount,
    required this.totalPlants,
    this.totalXp = 0,
    this.badgeCount = 0,
  });

  // -- Card palette constants --
  static const _amber = Color(0xFFFFB800);
  static const _blue = Color(0xFF0284C7);
  static const _darkGreen = Color(0xFF1E3E2B);
  static const _indigo = Color(0xFF4338CA);

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _ActivityCard(
          value: '$streakCount',
          label: 'Hari Konsisten',
          subtitle: 'Streak Berjalan',
          backgroundColor: _amber,
          watermarkIcon: Icons.local_fire_department,
        ),
        _ActivityCard(
          value: _formatNumber(totalXp),
          label: 'Total Poin XP',
          subtitle: 'Poin Pengalaman',
          backgroundColor: _blue,
          watermarkIcon: Icons.bolt,
        ),
        _ActivityCard(
          value: '$totalPlants',
          label: '$totalPlants Tanaman',
          subtitle: 'Total Koleksi',
          backgroundColor: _darkGreen,
          watermarkIcon: Icons.eco_outlined,
        ),
        _ActivityCard(
          value: '$badgeCount',
          label: '$badgeCount Lencana',
          subtitle: 'Pencapaian',
          backgroundColor: _indigo,
          watermarkIcon: Icons.emoji_events_outlined,
        ),
      ],
    );
  }
}

/// Single colorful stat card with a translucent watermark icon
/// clipped to the bottom-right corner.
class _ActivityCard extends StatelessWidget {
  final String value;
  final String label;
  final String subtitle;
  final Color backgroundColor;
  final IconData watermarkIcon;

  const _ActivityCard({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.backgroundColor,
    required this.watermarkIcon,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: backgroundColor),
        child: Stack(
          children: [
            // Watermark icon – bottom right, clipped
            Positioned(
              right: -14,
              bottom: -14,
              child: Icon(
                watermarkIcon,
                size: 72,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),

            // Foreground text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: AppTypography.displayLarge.copyWith(
                    fontSize: value.length > 5 ? 32 : 44,
                    color: Colors.white,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTypography.subheadlineBold.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption1Regular.copyWith(
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
