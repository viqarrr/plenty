import 'package:flutter/material.dart';

/// Custom clipper that creates a smooth concave circular cutout curve
/// along the bottom edge of the header, framing the circular profile avatar.
class HeaderConcaveClipper extends CustomClipper<Path> {
  /// Width from center to the start of the curve transition.
  final double cutoutRadius;

  /// Depth of the concave upward curve.
  final double curveDepth;

  const HeaderConcaveClipper({
    this.cutoutRadius = 58.0,
    this.curveDepth = 42.0,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    path.moveTo(0, 0);
    path.lineTo(0, h);

    // Flat line towards the cutout entry
    final entryX = cx - cutoutRadius - 32;
    path.lineTo(entryX > 0 ? entryX : 0, h);

    // Symmetrical cubic Bezier curve entering the circular cutout
    path.cubicTo(
      cx - cutoutRadius,
      h,
      cx - cutoutRadius + 12,
      h - curveDepth,
      cx,
      h - curveDepth,
    );

    // Symmetrical cubic Bezier curve exiting the circular cutout
    path.cubicTo(
      cx + cutoutRadius - 12,
      h - curveDepth,
      cx + cutoutRadius,
      h,
      cx + cutoutRadius + 32 < w ? cx + cutoutRadius + 32 : w,
      h,
    );

    // Flat line to bottom-right
    path.lineTo(w, h);
    path.lineTo(w, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant HeaderConcaveClipper oldClipper) {
    return oldClipper.cutoutRadius != cutoutRadius ||
        oldClipper.curveDepth != curveDepth;
  }
}
