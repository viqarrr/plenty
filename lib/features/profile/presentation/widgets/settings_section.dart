import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';

/// An iOS-style inset grouped section container.
///
/// Renders an optional uppercase [title] above a white rounded card
/// that wraps [children] separated by thin dividers.
class SettingsSection extends StatelessWidget {
  /// Optional section header displayed above the card.
  final String? title;

  /// The list of item widgets (typically [SettingsItemTile]) to render
  /// inside the card, separated by thin dividers.
  final List<Widget> children;

  const SettingsSection({
    super.key,
    this.title,
    required this.children,
  });

  /// Indent past the left padding (16) + icon (36) + gap (12) = 64.
  static const double _dividerIndent = 64;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              title!.toUpperCase(),
              style: AppTypography.footnoteRegular.copyWith(
                color: AppColors.muted,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 0.5,
                    thickness: 0.5,
                    indent: _dividerIndent,
                    color: AppColors.border,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
