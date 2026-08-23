import 'package:flutter/material.dart';
import 'package:plenty/core/domain/models/badge_item.dart';
import 'package:plenty/features/community/domain/repositories/community_repository.dart';
import 'package:plenty/features/profile/presentation/screens/badge_detail_screen.dart';

/// Legacy shim delegating detail presentation to the full-screen [BadgeDetailScreen].
class BadgeDetailModal extends StatelessWidget {
  final BadgeItem badge;
  final ICommunityRepository? communityRepository;

  const BadgeDetailModal({
    super.key,
    required this.badge,
    this.communityRepository,
  });

  /// Static helper to display the full screen badge detail screen.
  static Future<void> show(
    BuildContext context,
    BadgeItem badge, {
    ICommunityRepository? communityRepository,
  }) {
    return BadgeDetailScreen.open(
      context,
      badge,
      communityRepository: communityRepository,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BadgeDetailScreen(
      badge: badge,
      communityRepository: communityRepository,
    );
  }
}
