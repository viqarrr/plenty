import 'dart:io';
import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/presentation/home/profile/header_concave_clipper.dart';

/// Full-width profile header with a dark forest background, a smooth concave
/// cutout curve, an overlapping circular avatar, name, and username.
class ProfileHeader extends StatelessWidget {
  final String profileName;
  final String username;
  final String? avatarPath;

  /// Called when the gear icon is tapped.
  final VoidCallback? onSettingsTap;

  const ProfileHeader({
    super.key,
    required this.profileName,
    this.username = 'alex_plants',
    this.avatarPath,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final cleanUsername = username.startsWith('@') ? username : '@$username';
    final photo = avatarPath;
    final hasPhoto = photo != null && photo.isNotEmpty;

    return Column(
      children: [
        // ── Top Curved Header & Nestled Avatar ──
        SizedBox(
          height: 172,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Dark forest background with concave circular cutout curve
              ClipPath(
                clipper: const HeaderConcaveClipper(
                  cutoutRadius: 58.0,
                  curveDepth: 42.0,
                ),
                child: Container(
                  height: 148,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.deepForest, AppColors.forest],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // Settings gear button (top right)
              Positioned(
                top: 12,
                right: 16,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onSettingsTap,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Circular Avatar (centered, overlapping the curve)
              Positioned(
                top: 60,
                child: _AvatarContainer(
                  photo: photo,
                  hasPhoto: hasPhoto,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── User Information (Name & Username) ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Text(
                profileName,
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkSoft,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                cleanUsername,
                style: AppTypography.subheadlineBold.copyWith(
                  color: AppColors.muted,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Circular avatar widget with surface border and soft drop shadow.
class _AvatarContainer extends StatelessWidget {
  final String? photo;
  final bool hasPhoto;

  const _AvatarContainer({
    required this.photo,
    required this.hasPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.pastelGreenBg,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: hasPhoto
            ? (photo!.startsWith('http://') || photo!.startsWith('https://'))
                ? Image.network(
                    photo!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.person,
                      size: 52,
                      color: AppColors.forest,
                    ),
                  )
                : photo!.startsWith('assets/')
                    ? Image.asset(
                        photo!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.person,
                          size: 52,
                          color: AppColors.forest,
                        ),
                      )
                    : Image.file(
                        File(photo!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.person,
                          size: 52,
                          color: AppColors.forest,
                        ),
                      )
            : const Icon(
                Icons.person,
                size: 52,
                color: AppColors.forest,
              ),
      ),
    );
  }
}
