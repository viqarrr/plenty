import 'dart:io';

import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/di/injector.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/badge_ui_extension.dart';
import 'package:plenty/features/community/domain/models/community_post.dart';
import 'package:plenty/features/profile/domain/models/badge_item.dart';
import 'package:plenty/features/profile/presentation/screens/badge_detail_screen.dart';

/// Clean, modern post card for the community feed supporting text,
/// category tags, attached achievement badges, image attachments, and interactions.
class CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback? onLikeTap;
  final VoidCallback? onCommentTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;

  const CommunityPostCard({
    super.key,
    required this.post,
    this.onLikeTap,
    this.onCommentTap,
    this.onShareTap,
    this.onEditTap,
    this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Author Header Row ──
          Row(
            children: [
              _AuthorAvatar(
                avatarUrl: post.authorAvatar,
                name: post.authorName,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: AppTypography.headlineSemiBold.copyWith(
                        fontSize: 15,
                        color: AppColors.inkDark,
                      ),
                    ),
                    Text(
                      post.timeAgo,
                      style: AppTypography.caption1Regular.copyWith(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _CategoryPill(category: post.category),
              if (post.isAuthor &&
                  (onEditTap != null || onDeleteTap != null)) ...[
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: AppColors.muted,
                    size: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEditTap?.call();
                    } else if (value == 'delete') {
                      onDeleteTap?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEditTap != null)
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: AppColors.inkDark,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Edit Postingan',
                              style: AppTypography.calloutRegular.copyWith(
                                color: AppColors.inkDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (onDeleteTap != null)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Hapus Postingan',
                              style: AppTypography.calloutRegular.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // ── Content Description ──
          Text(
            post.content,
            style: AppTypography.bodyRegular.copyWith(
              color: AppColors.inkBody,
              height: 1.45,
            ),
          ),

          // ── Embedded Badge Attachment Card ──
          if (post.attachedBadge != null) ...[
            const SizedBox(height: 12),
            _AttachedBadgeCard(badge: post.attachedBadge!),
          ],

          // ── Image Attachment ──
          if (post.imagePath != null && post.imagePath!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _PostImageAttachment(imagePath: post.imagePath!),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),

          // ── Action Footer ──
          Row(
            children: [
              // Like / Kudos Button
              GestureDetector(
                onTap: onLikeTap,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Icon(
                      post.isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 20,
                      color: post.isLiked
                          ? AppColors.pastelRedText
                          : AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.likesCount}',
                      style: AppTypography.caption1Bold.copyWith(
                        color: post.isLiked
                            ? AppColors.pastelRedText
                            : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),
              GestureDetector(
                onTap: onCommentTap,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.commentsCount}',
                      style: AppTypography.caption1Bold.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              // Tombol share di-hide terlebih dahulu
              // const Spacer(),
              // onShareTap != null
              //     ? IconButton(
              //         onPressed: onShareTap,
              //         icon: const Icon(
              //           Icons.share_outlined,
              //           size: 19,
              //           color: AppColors.muted,
              //         ),
              //         padding: EdgeInsets.zero,
              //         constraints: const BoxConstraints(),
              //       )
              //     : const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }
}

/// Category Pill with distinctive color tokens per category
class _CategoryPill extends StatelessWidget {
  final String category;

  const _CategoryPill({required this.category});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;

    switch (category.toLowerCase()) {
      case 'pertanyaan':
        bg = AppColors.pastelBlueBg;
        text = AppColors.pastelBlueText;
        label = 'Pertanyaan';
        break;
      case 'pencapaian':
        bg = AppColors.pastelGreenBg;
        text = AppColors.pastelGreenText;
        label = 'Pencapaian';
        break;
      case 'tips':
      default:
        bg = AppColors.pastelYellowBg;
        text = AppColors.pastelYellowText;
        label = 'Tips & Trik';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTypography.caption2Bold.copyWith(color: text, fontSize: 10.5),
      ),
    );
  }
}

/// Embedded Card for Attached Achievement Badges
class _AttachedBadgeCard extends StatelessWidget {
  final BadgeItem badge;

  const _AttachedBadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final badgeRepo = Injector.badgeRepository;
        final userBadgeResult = await badgeRepo.getBadgeById(badge.id);
        final userBadge = userBadgeResult.dataOrNull;
        if (context.mounted) {
          final targetBadge =
              userBadge ??
              badge.copyWith(
                isUnlocked: false,
                progress: 0,
                unlockedDate: null,
              );
          BadgeDetailScreen.open(context, targetBadge);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.pastelGreenBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.pastelGreenText.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            // Badge Circle Icon
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: badge.bgColor,
                      border: Border.all(
                        color: badge.accentColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        badge.icon,
                        color: badge.accentColor,
                        size: 22,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: badge.accentColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Text(
                        'Lv.${badge.level}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pencapaian Terbuka! 🏆',
                    style: AppTypography.caption2Bold.copyWith(
                      color: AppColors.forest,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    badge.title,
                    style: AppTypography.headlineSemiBold.copyWith(
                      fontSize: 14,
                      color: AppColors.inkDark,
                    ),
                  ),
                  Text(
                    badge.desc,
                    style: AppTypography.caption1Regular.copyWith(
                      color: AppColors.muted,
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.forest,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Image Attachment with file / asset / network fallback
class _PostImageAttachment extends StatelessWidget {
  final String imagePath;

  const _PostImageAttachment({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    final trimmedPath = imagePath.trim();
    if (trimmedPath.startsWith('http://') ||
        trimmedPath.startsWith('https://')) {
      imageWidget = Image.network(
        trimmedPath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _errorPlaceholder(),
      );
    } else if (trimmedPath.startsWith('assets/')) {
      imageWidget = Image.asset(
        trimmedPath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _errorPlaceholder(),
      );
    } else {
      final file = File(trimmedPath);
      if (file.existsSync()) {
        imageWidget = Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _errorPlaceholder(),
        );
      } else {
        imageWidget = _errorPlaceholder();
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 180,
        width: double.infinity,
        color: AppColors.canvasDefault,
        child: imageWidget,
      ),
    );
  }

  Widget _errorPlaceholder() {
    return Container(
      color: AppColors.canvasDefault,
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined, color: AppColors.muted),
      ),
    );
  }
}

/// Author Avatar with letter fallback
class _AuthorAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;

  const _AuthorAvatar({this.avatarUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      if (avatarUrl!.startsWith('http')) {
        return CircleAvatar(
          radius: 18,
          backgroundImage: NetworkImage(avatarUrl!),
        );
      } else if (avatarUrl!.startsWith('assets/')) {
        return CircleAvatar(
          radius: 18,
          backgroundImage: AssetImage(avatarUrl!),
        );
      } else {
        final file = File(avatarUrl!);
        if (file.existsSync()) {
          return CircleAvatar(radius: 18, backgroundImage: FileImage(file));
        }
      }
    }

    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.pastelGreenBg,
      child: Text(
        initial,
        style: AppTypography.headlineSemiBold.copyWith(
          color: AppColors.forest,
          fontSize: 14,
        ),
      ),
    );
  }
}
