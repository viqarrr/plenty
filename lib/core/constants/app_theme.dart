import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_typography.dart';

/// App theme configurations for Light and Dark modes.
abstract final class AppTheme {
  AppTheme._();

  static ThemeData light = ThemeData(
    useMaterial3: true,
    fontFamily: AppTypography.fontFamily,
    colorScheme: const ColorScheme.light(
      primary: AppColors.forest,
      onPrimary: AppColors.surface,
      secondary: AppColors.emerald,
      onSecondary: AppColors.surface,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.pastelRedText,
      onError: AppColors.surface,
      outline: AppColors.border,
    ),
    scaffoldBackgroundColor: AppColors.canvasDefault,
    textTheme: TextTheme(
      displayLarge: AppTypography.largeTitleBold,
      displayMedium: AppTypography.largeTitleRegular,
      displaySmall: AppTypography.title2Bold,
      headlineLarge: AppTypography.title2Bold,
      headlineMedium: AppTypography.title2Regular,
      headlineSmall: AppTypography.headline,
      titleLarge: AppTypography.headline,
      titleMedium: AppTypography.bodyBold,
      titleSmall: AppTypography.calloutBold,
      bodyLarge: AppTypography.bodyRegular,
      bodyMedium: AppTypography.calloutRegular,
      bodySmall: AppTypography.subheadlineRegular,
      labelLarge: AppTypography.calloutBold,
      labelMedium: AppTypography.footnoteBold,
      labelSmall: AppTypography.caption1Regular,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.canvasDefault,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.title2Bold,
      iconTheme: const IconThemeData(color: AppColors.ink),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.surface,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.muted,
        elevation: 0,
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: AppTypography.calloutBold,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.border),
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: AppTypography.calloutBold,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size(44, 44),
        textStyle: AppTypography.calloutBold,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size(44, 44),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    iconTheme: const IconThemeData(color: AppColors.ink, size: 24),
    applyElevationOverlayColor: false,
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: AppTypography.fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.forestDark,
      onPrimary: AppColors.canvasDefaultDark,
      secondary: AppColors.emeraldDark,
      onSecondary: AppColors.canvasDefaultDark,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.inkDark,
      error: AppColors.pastelRedTextDark,
      onError: AppColors.canvasDefaultDark,
      outline: AppColors.borderDark,
    ),
    scaffoldBackgroundColor: AppColors.canvasDefaultDark,
    textTheme: TextTheme(
      displayLarge: AppTypography.largeTitleBold,
      displayMedium: AppTypography.largeTitleRegular,
      displaySmall: AppTypography.title2Bold,
      headlineLarge: AppTypography.title2Bold,
      headlineMedium: AppTypography.title2Regular,
      headlineSmall: AppTypography.headline,
      titleLarge: AppTypography.headline,
      titleMedium: AppTypography.bodyBold,
      titleSmall: AppTypography.calloutBold,
      bodyLarge: AppTypography.bodyRegular,
      bodyMedium: AppTypography.calloutRegular,
      bodySmall: AppTypography.subheadlineRegular,
      labelLarge: AppTypography.calloutBold,
      labelMedium: AppTypography.footnoteBold,
      labelSmall: AppTypography.caption1Regular,
    ).apply(bodyColor: AppColors.inkDark, displayColor: AppColors.inkDark),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.canvasDefaultDark,
      foregroundColor: AppColors.inkDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.title2Bold,
      iconTheme: const IconThemeData(color: AppColors.inkDark),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.inkDark,
        foregroundColor: AppColors.canvasDefaultDark,
        disabledBackgroundColor: AppColors.borderDark,
        disabledForegroundColor: AppColors.mutedDark,
        elevation: 0,
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: AppTypography.calloutBold,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.inkDark,
        side: const BorderSide(color: AppColors.borderDark),
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: AppTypography.calloutBold,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.inkDark,
        minimumSize: const Size(44, 44),
        textStyle: AppTypography.calloutBold,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.inkDark,
        minimumSize: const Size(44, 44),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceDark,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.borderDark),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderDark,
      thickness: 1,
      space: 1,
    ),
    iconTheme: const IconThemeData(color: AppColors.inkDark, size: 24),
    applyElevationOverlayColor: false,
  );
}
