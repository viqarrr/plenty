import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';

/// A single row inside an iOS-style inset grouped settings section.
///
/// Supports two display modes:
/// - **Label + value** (when [value] is provided): small gray label above
///   bold value text.
/// - **Single line** (when [value] is `null`): the [label] is rendered as
///   primary text, styled as destructive when [isDestructive] is `true`.
class SettingsItemTile extends StatelessWidget {
  /// Leading icon displayed inside a soft circle.
  final IconData icon;

  /// Primary text — shown as a small caption when [value] is set,
  /// or as the main text when [value] is `null`.
  final String label;

  /// Optional bold value text rendered below [label].
  final String? value;

  /// Optional trailing widget (chevron, lock icon, text, etc.).
  final Widget? trailing;

  /// Callback fired when the tile is tapped.
  final VoidCallback? onTap;

  /// When `true`, the icon and label adopt a red/danger palette.
  final bool isDestructive;

  const SettingsItemTile({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg =
        isDestructive ? AppColors.pastelRedBg : AppColors.searchBarSurface;
    final iconColor =
        isDestructive ? AppColors.pastelRedText : AppColors.muted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ── Leading icon circle ──
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),

            // ── Text content ──
            Expanded(child: _buildTextContent()),

            // ── Trailing widget ──
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextContent() {
    // Two-line mode: small label + bold value
    if (value != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption1Regular.copyWith(
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value!,
            style: AppTypography.subheadlineBold,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    // Single-line mode
    return Text(
      label,
      style: isDestructive
          ? AppTypography.calloutBold.copyWith(color: AppColors.pastelRedText)
          : AppTypography.calloutRegular,
    );
  }
}
