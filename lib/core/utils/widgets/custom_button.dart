import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_typography.dart';

/// Reusable Button Component following Figma UI Plenty Design System.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isLoading;
  final IconData? icon;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? textColor;
  final double height;
  final BorderRadius? borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false,
    this.isLoading = false,
    this.icon,
    this.leading,
    this.backgroundColor,
    this.textColor,
    this.height = 50,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(12);

    if (isLoading) {
      return SizedBox(
        height: height,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: AppColors.forest,
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }

    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? AppColors.inkSoft,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          minimumSize: Size.fromHeight(height),
          shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
        ),
        child: _buildContent(textColor ?? AppColors.inkSoft),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.forest,
        foregroundColor: textColor ?? Colors.white,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.muted,
        minimumSize: Size.fromHeight(height),
        shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
        elevation: 0,
      ),
      child: _buildContent(textColor ?? Colors.white),
    );
  }

  Widget _buildContent(Color color) {
    if (leading != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          leading!,
          const SizedBox(width: 10),
          Text(
            text,
            style: AppTypography.calloutBold.copyWith(color: color),
          ),
        ],
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Text(
            text,
            style: AppTypography.calloutBold.copyWith(color: color),
          ),
        ],
      );
    }

    return Text(
      text,
      style: AppTypography.calloutBold.copyWith(color: color),
    );
  }
}
