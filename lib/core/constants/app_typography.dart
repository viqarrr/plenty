import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized typography definitions using Plus Jakarta Sans from Figma tokens.
abstract final class AppTypography {
  AppTypography._();

  static final String fontFamily =
      GoogleFonts.plusJakartaSans().fontFamily ?? 'Plus Jakarta Sans';

  /// Display / Hero Titles (36px Bold)
  static final TextStyle displayLarge = GoogleFonts.plusJakartaSans(
    textStyle: const TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      height: 1.0,
      letterSpacing: 0,
    ),
  );

  /// Brand Title (34px - 32px Bold)
  static final TextStyle largeTitleBold = GoogleFonts.plusJakartaSans(
    textStyle: const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w900,
      height: 1.25,
      letterSpacing: -0.68,
    ),
  );

  static final TextStyle largeTitleRegular = GoogleFonts.plusJakartaSans(
    textStyle: const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w400,
      height: 1.25,
      letterSpacing: 0,
    ),
  );

  /// Section Title (22px - 24px Bold)
  static final TextStyle title2Bold = GoogleFonts.plusJakartaSans(
    textStyle: const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 28 / 22,
      letterSpacing: 0,
    ),
  );

  static final TextStyle title2Regular = GoogleFonts.plusJakartaSans(
    textStyle: const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w400,
      height: 28 / 22,
      letterSpacing: 0,
    ),
  );

  /// Headline (17px SemiBold / Bold)
  static final TextStyle headline = GoogleFonts.plusJakartaSans(
    textStyle: const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      height: 22 / 17,
      letterSpacing: 0,
    ),
  );

  static final TextStyle headlineSemiBold = GoogleFonts.plusJakartaSans(
    textStyle: const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 22 / 17,
      letterSpacing: 0,
    ),
  );

  /// Body (16px / 17px Regular & Bold)
  static final TextStyle bodyRegular = GoogleFonts.plusJakartaSans(
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 24 / 16,
      letterSpacing: 0,
    ),
  );

  static final TextStyle bodyBold = GoogleFonts.plusJakartaSans(
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      height: 24 / 16,
      letterSpacing: 0,
    ),
  );

  /// Callout / Buttons (16px Bold)
  static final TextStyle calloutBold = GoogleFonts.plusJakartaSans(
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      height: 22 / 16,
      letterSpacing: 0,
    ),
  );

  static final TextStyle calloutRegular = GoogleFonts.plusJakartaSans(
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 21 / 16,
      letterSpacing: 0,
    ),
  );

  /// Subheadline (14px Regular & Bold)
  static final TextStyle subheadlineRegular = GoogleFonts.plusJakartaSans(
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 20 / 14,
      letterSpacing: 0,
    ),
  );

  static final TextStyle subheadlineBold = GoogleFonts.plusJakartaSans(
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      height: 20 / 14,
      letterSpacing: 0,
    ),
  );

  /// Footnote (13px Regular & Bold)
  static final TextStyle footnoteRegular = GoogleFonts.plusJakartaSans(
    textStyle: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 18 / 13,
      letterSpacing: 0,
    ),
  );

  static final TextStyle footnoteBold = GoogleFonts.plusJakartaSans(
    textStyle: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      height: 18 / 13,
      letterSpacing: 0,
    ),
  );

  /// Caption 1 (12px Regular & Bold)
  static final TextStyle caption1Regular = GoogleFonts.plusJakartaSans(
    textStyle: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 16 / 12,
      letterSpacing: 0,
    ),
  );

  static final TextStyle caption1Bold = GoogleFonts.plusJakartaSans(
    textStyle: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      height: 16 / 12,
      letterSpacing: 0,
    ),
  );

  /// Caption 2 / Badge Tags (10px / 11px Bold)
  static final TextStyle caption2Bold = GoogleFonts.plusJakartaSans(
    textStyle: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      height: 15 / 10,
      letterSpacing: 1.0,
    ),
  );

  static final TextStyle badge = GoogleFonts.plusJakartaSans(
    textStyle: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      height: 17 / 11,
      letterSpacing: 0.55,
    ),
  );
}
