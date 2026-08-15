import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_typography.dart';
import 'package:plenty/features/plant/presentation/home/widgets/social_post_card.dart';

/// Social and community feed tab widget.
class SocialTab extends StatelessWidget {
  const SocialTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sosial & Komunitas',
            style: AppTypography.title2Bold.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            'Bagikan kebahagiaan menanam bersama para kolektor di sekitarmu.',
            style: AppTypography.footnoteRegular.copyWith(
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: const [
                SocialPostCard(
                  author: 'Anna Wijaya',
                  time: '2 jam yang lalu',
                  content:
                      'Monstera deliciosa saya akhirnya membelah daun baru hari ini! Senang sekali rasanya melihat hasil penyiraman berkala yang disiplin.',
                  plantTag: 'Monstera',
                ),
                SizedBox(height: 16),
                SocialPostCard(
                  author: 'Budi Santoso',
                  time: '5 jam yang lalu',
                  content:
                      'Ada yang tahu cara menangani busuk akar pada Snake Plant? Sepertinya media tanahnya terlalu padat.',
                  plantTag: 'Snake Plant',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
