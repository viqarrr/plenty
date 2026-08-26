import 'package:flutter/material.dart';
import 'package:plenty/features/community/domain/repositories/community_repository.dart';
import 'package:plenty/features/profile/domain/models/badge_item.dart';
import 'package:plenty/features/profile/presentation/screens/badge_detail_screen.dart';

/// Legacy shim delegating detail presentation to the full-screen [BadgeDetailScreen].
class BadgeDetailModal extends StatelessWidget {
  final BadgeItem badge;
  final ICommunityRepository? communityRepository;
  final bool? isAlreadyShared;
  final void Function(BuildContext context)? onNavigateToHomeScreen;

  const BadgeDetailModal({
    super.key,
    required this.badge,
    this.communityRepository,
    this.isAlreadyShared,
    this.onNavigateToHomeScreen,
  });

  /// Static helper to display the full screen badge detail screen.
  static Future<void> show(
    BuildContext context,
    BadgeItem badge, {
    ICommunityRepository? communityRepository,
    bool? isAlreadyShared,
    void Function(BuildContext context)? onNavigateToHomeScreen,
  }) {
    return BadgeDetailScreen.open(
      context,
      badge,
      communityRepository: communityRepository,
      isAlreadyShared: isAlreadyShared,
      onNavigateToHomeScreen: onNavigateToHomeScreen,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BadgeDetailScreen(
      badge: badge,
      communityRepository: communityRepository,
      isAlreadyShared: isAlreadyShared,
      onNavigateToHomeScreen: onNavigateToHomeScreen,
    );
  }
}
