import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  AppTypography._();

  static final fontFamily = GoogleFonts.plusJakartaSans().fontFamily!;

  static final largeTitleRegular = GoogleFonts.plusJakartaSans(
    textStyle: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w400,
      height: 41 / 34,
      letterSpacing: 0.37,
    ),
  );

  static final largeTitleBold = GoogleFonts.plusJakartaSans(
    textStyle: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      height: 41 / 34,
      letterSpacing: 0.37,
    ),
  );

  static final title2Regular = GoogleFonts.plusJakartaSans(
    textStyle: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w400,
      height: 28 / 22,
      letterSpacing: 0.35,
    ),
  );

  static final title2Bold = GoogleFonts.plusJakartaSans(
    textStyle: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 28 / 22,
      letterSpacing: 0.35,
    ),
  );

  static final headline = GoogleFonts.plusJakartaSans(
    textStyle: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 22 / 17,
      letterSpacing: -0.41,
    ),
  );

  static final subheadlineRegular = GoogleFonts.plusJakartaSans(
    textStyle: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 20 / 15,
      letterSpacing: -0.24,
    ),
  );

  static final subheadlineBold = GoogleFonts.plusJakartaSans(
    textStyle: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 20 / 15,
      letterSpacing: -0.24,
    ),
  );

  static final bodyRegular = GoogleFonts.plusJakartaSans(
    textStyle: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w400,
      height: 22 / 17,
      letterSpacing: -0.41,
    ),
  );

  static final bodyBold = GoogleFonts.plusJakartaSans(
    textStyle: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 22 / 17,
      letterSpacing: -0.41,
    ),
  );

  static final calloutRegular = GoogleFonts.plusJakartaSans(
    textStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 21 / 16,
      letterSpacing: -0.32,
    ),
  );

  static final calloutBold = GoogleFonts.plusJakartaSans(
    textStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 21 / 16,
      letterSpacing: -0.32,
    ),
  );

  static final footnoteRegular = GoogleFonts.plusJakartaSans(
    textStyle: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 18 / 13,
      letterSpacing: -0.08,
    ),
  );

  static final footnoteBold = GoogleFonts.plusJakartaSans(
    textStyle: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 18 / 13,
      letterSpacing: -0.08,
    ),
  );

  static final caption1Regular = GoogleFonts.plusJakartaSans(
    textStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 16 / 12,
    ),
  );
  static final caption1Bold = GoogleFonts.plusJakartaSans(
    textStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 16 / 12,
    ),
  );
}
