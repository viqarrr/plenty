import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_typography.dart';

/// Social OAuth Button (e.g. Google Sign-In) matching Figma Design.
class SocialAuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;

  const SocialAuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 50,
        child: Center(
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

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.inkSoft,
        side: const BorderSide(color: AppColors.border, width: 1.5),
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon ?? _defaultGoogleIcon(),
          const SizedBox(width: 12),
          Text(
            text,
            style: AppTypography.calloutBold.copyWith(
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultGoogleIcon() {
    return Image.network(
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1024px-Google_%22G%22_logo.svg.png',
      height: 20,
      width: 20,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.g_mobiledata_rounded,
        size: 24,
        color: AppColors.forest,
      ),
    );
  }
}
