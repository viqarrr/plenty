import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// A clean, editorial iOS-style hero illustration container for Plenty.
///
/// Features:
/// - "Soft Layered Organic Backdrop": 2-3 overlapping sweeping organic
///   curved shapes (220-250dp) with soft, airy opacity (12-22%).
/// - Smooth sweeping elliptical curvature without lumps, sharp kinks, or rigid blobs.
/// - Unwrapped, floating focal animation in the foreground using Lottie animations
///   ([animationPath], [repeatAnimation] = false), image assets, or vector icons.
class HeroIllustrationContainer extends StatelessWidget {
  /// The asset path to a Lottie JSON animation.
  final String? animationPath;

  /// Whether the Lottie animation should loop. Defaults to false.
  final bool repeatAnimation;

  /// The asset path to an image if using an image asset instead of [animationPath].
  final String? imagePath;

  /// The vector icon if using an icon instead.
  final IconData? icon;

  /// Optional custom child widget to display in the center.
  final Widget? child;

  /// Overall size of the layered backdrop canvas. Defaults to 280.
  final double size;

  /// Size of the central floating animation/icon. Defaults to 260.
  final double iconSize;

  /// Color of the central floating icon/image if applicable. Defaults to Deep Forest Green `#2D4A3E`.
  final Color iconColor;

  /// Primary color for the base organic backdrop layer. Defaults to Sage Green `#4A6B5B`.
  final Color primaryColor;

  /// Secondary color for the counter-rotated organic layer. Defaults to Soft Matcha `#5A7D6D`.
  final Color? secondaryColor;

  /// Index to gracefully vary the sweeping layer rotation angles per slide.
  final int slideIndex;

  /// Whether to render the organic blob backdrop behind the illustration.
  /// Defaults to false for an unbounded, clean, expansive hero presentation.
  final bool showBackdrop;

  const HeroIllustrationContainer({
    super.key,
    this.animationPath,
    this.repeatAnimation = false,
    this.imagePath,
    this.icon,
    this.child,
    this.size = 280,
    this.iconSize = 260,
    this.iconColor = const Color(0xFF2D4A3E),
    this.primaryColor = const Color(0xFF4A6B5B),
    this.secondaryColor,
    this.slideIndex = 0,
    this.showBackdrop = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSecondaryColor =
        secondaryColor ?? _lightenColor(primaryColor, 0.10);

    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: showBackdrop
            ? Stack(
                alignment: Alignment.center,
                children: [
                  // Layer 1: Soft Layered Organic Backdrop (Custom Painted)
                  CustomPaint(
                    size: Size(size, size),
                    painter: _LayeredOrganicBackdropPainter(
                      primaryColor: primaryColor,
                      secondaryColor: effectiveSecondaryColor,
                      slideIndex: slideIndex,
                    ),
                  ),

                  // Layer 2: Floating Foreground Focal Animation / Icon
                  Center(
                    child: _buildFocalPoint(),
                  ),
                ],
              )
            : Center(
                child: _buildFocalPoint(),
              ),
      ),
    );
  }

  Widget _buildFocalPoint() {
    if (child != null) {
      return child!;
    }

    if (animationPath != null) {
      return Lottie.asset(
        animationPath!,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
        repeat: repeatAnimation,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.eco_rounded,
            size: iconSize * 0.45,
            color: iconColor,
          );
        },
      );
    }

    if (imagePath != null) {
      return Image.asset(
        imagePath!,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
        color: iconColor,
        colorBlendMode: BlendMode.srcIn,
        filterQuality: FilterQuality.medium,
      );
    }

    if (icon != null) {
      return Icon(
        icon,
        size: iconSize,
        color: iconColor,
      );
    }

    // Default animation fallback from assets/animations
    return Lottie.asset(
      'assets/animations/leaf_line.json',
      width: iconSize,
      height: iconSize,
      fit: BoxFit.contain,
      repeat: repeatAnimation,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.eco_rounded,
          size: iconSize * 0.45,
          color: iconColor,
        );
      },
    );
  }

  Color _lightenColor(Color c, double factor) {
    final hsl = HSLColor.fromColor(c);
    final lightness = (hsl.lightness + factor).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}

/// Custom painter rendering a soft, layered organic backdrop inspired by
/// high-end iOS editorial design.
///
/// Employs 2-3 overlapping sweeping organic curves with gentle 12-22% opacity,
/// counter-rotations, and a soft luminous central aura.
class _LayeredOrganicBackdropPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final int slideIndex;

  const _LayeredOrganicBackdropPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.slideIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width;
    final h = size.height;

    // Harmonic rotation offset per slide for organic variation
    final angleShift = (slideIndex % 3) * 0.35;

    // -------------------------------------------------------------------------
    // 1. Layer 1 (Back Layer): Large Sweeping Elliptical Curve
    //    Soft opacity ~14%, generous diameter, smooth organic corner flow
    // -------------------------------------------------------------------------
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-0.20 + angleShift);

    final backRect = Rect.fromCenter(
      center: Offset(-w * 0.02, h * 0.02),
      width: w * 0.94,
      height: h * 0.80,
    );
    final backRRect = RRect.fromRectAndCorners(
      backRect,
      topLeft: Radius.circular(w * 0.44),
      topRight: Radius.circular(w * 0.36),
      bottomRight: Radius.circular(w * 0.42),
      bottomLeft: Radius.circular(w * 0.38),
    );

    final backPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(backRRect, backPaint);
    canvas.restore();

    // -------------------------------------------------------------------------
    // 2. Layer 2 (Middle Layer): Counter-Rotated Organic Curve
    //    Slightly brighter/complementary tone, counter-angle, opacity ~20%
    // -------------------------------------------------------------------------
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(0.30 - angleShift * 0.9);

    final midRect = Rect.fromCenter(
      center: Offset(w * 0.03, -h * 0.025),
      width: w * 0.84,
      height: h * 0.74,
    );
    final midRRect = RRect.fromRectAndCorners(
      midRect,
      topLeft: Radius.circular(w * 0.38),
      topRight: Radius.circular(w * 0.44),
      bottomRight: Radius.circular(w * 0.36),
      bottomLeft: Radius.circular(w * 0.42),
    );

    final midPaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(midRRect, midPaint);
    canvas.restore();

    // -------------------------------------------------------------------------
    // 3. Layer 3 (Center Aura Cushion):
    //    Soft luminous radial blend right behind the central focal animation
    // -------------------------------------------------------------------------
    final auraRadius = w * 0.34;
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: 0.16),
          primaryColor.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(center: Offset(cx, cy), radius: auraRadius),
      )
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), auraRadius, auraPaint);
  }

  @override
  bool shouldRepaint(covariant _LayeredOrganicBackdropPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.slideIndex != slideIndex;
  }
}
