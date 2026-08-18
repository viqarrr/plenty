import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/presentation/forum/social_post_card.dart';

class SocialTab extends StatelessWidget {
  const SocialTab({super.key});

  static const List<Map<String, dynamic>> mockPosts = [
    {
      'authorName': 'Siti Rahma',
      'timeAgo': '2 jam lalu',
      'plantName': 'Monstera Deliciosa',
      'content':
          'Daun barunya akhirnya mekar sempurna dengan 4 robekan! Senang banget progress sebulan ini.',
      'likesCount': 24,
      'commentsCount': 5,
    },
    {
      'authorName': 'Budi Santoso',
      'timeAgo': '5 jam lalu',
      'plantName': 'Snake Plant (Sansevieria)',
      'content':
          'Tanaman paling tahan banting! Ditinggal dinas 2 minggu tetap segar bugar.',
      'likesCount': 42,
      'commentsCount': 8,
    },
    {
      'authorName': 'Alya Putri',
      'timeAgo': '1 hari lalu',
      'plantName': 'Calathea Orbifolia',
      'content':
          'Tips melembabkan ruangan untuk Calathea: semprot sprayer halus tiap pagi dan pakai humidifier.',
      'likesCount': 56,
      'commentsCount': 12,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasDefault,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Komunitas Plenty',
          style: AppTypography.title2Bold.copyWith(color: AppColors.inkSoft),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        itemCount: mockPosts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final post = mockPosts[index];
          return SocialPostCard(
            authorName: post['authorName'] as String,
            timeAgo: post['timeAgo'] as String,
            plantName: post['plantName'] as String,
            content: post['content'] as String,
            likesCount: post['likesCount'] as int,
            commentsCount: post['commentsCount'] as int,
          );
        },
      ),
    );
  }
}
