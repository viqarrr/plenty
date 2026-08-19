import 'package:flutter/painting.dart';

/// Centralized color tokens extracted directly from Figma UI Plenty (AKfevjYc3I787wEdWMzVx1).
abstract final class AppColors {
  AppColors._();

  // ----- Brand & Primary Colors -----
  static const Color forest = Color(0xFF2D4F1E);
  static const Color emerald = Color(0xFF2D6A4F);
  static const Color darkGreen = Color(0xFF1B4332);
  static const Color deepForest = Color(0xFF1C3F32);
  static const Color mint = Color(0xFF34C77B);
  static const Color accentGreen = Color(0xFF44F1A6);
  static const Color lightGreen = Color(0xFF4ECA78);
  static const Color pastelGreenHighlight = Color(0xFF74E39A);

  // ----- Light Canvas & Surfaces -----
  static const Color canvasDefault = Color(0xFFF1F3F5);
  static const Color canvasSurface = Color(0xFFFBFBFD);
  static const Color canvasBackground = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color searchBarSurface = Color(0xFFF2F2F7);

  // ----- Text & Neutral Labels -----
  static const Color ink = Color(0xFF000000);
  static const Color inkDark = Color(0xFF0B0B0B);
  static const Color inkSoft = Color(0xFF1D1D1F);
  static const Color inkBody = Color(0xFF363D45);
  static const Color muted = Color(0xFF66706B);
  static const Color mutedGray = Color(0xFF818E9C);
  static const Color textSecondary = Color(0xFF86868B);
  static const Color border = Color(0xFFE8EAED);
  static const Color borderLight = Color(0xFFEAEAEA);
  static const Color borderSubtle = Color(0xFFAFB7C0);

  // ----- Status & Pastel Accents -----
  static const Color pastelGreenBg = Color(0xFFEBF7F1);
  static const Color pastelGreenText = Color(0xFF2D6A4F);

  static const Color pastelBlueBg = Color(0xFFE3F0FF);
  static const Color pastelBlueText = Color(0xFF1F6C9F);

  static const Color pastelYellowBg = Color(0xFFFBF3DB);
  static const Color pastelYellowText = Color(0xFF956400);

  static const Color pastelRedBg = Color(0xFFFDEBEC);
  static const Color pastelRedText = Color(0xFF9F2F2D);

  static const Color pastelPurpleBg = Color(0xFFEFEBF7);
  static const Color pastelPurpleText = Color(0xFF5B4B8A);

  static const Color pastelGrayBg = Color(0xFFF0F0EF);
  static const Color pastelGrayText = Color(0xFF6B6B67);

  // ----- Alert & Accent Colors -----
  static const Color error = Color(0xFFFF3B30);
  static const Color errorAlt = Color(0xFFEF4444);
  static const Color warning = Color(0xFFFFB000);
  static const Color warningAlt = Color(0xFFFBBC05);
  static const Color info = Color(0xFF4285F4);
  static const Color success = Color(0xFF34A853);
  static const Color petFriendlyBg = Color(0xFFE6F7F5);
  static const Color petFriendlyText = Color(0xFF0D9488);

  // ----- Tier Badges -----
  static const Color tierNormalBg = pastelGrayBg;
  static const Color tierNormalText = pastelGrayText;

  static const Color tierEliteBg = pastelGreenBg;
  static const Color tierEliteText = pastelGreenText;

  static const Color tierSpecialBg = pastelBlueBg;
  static const Color tierSpecialText = pastelBlueText;

  static const Color tierEpicBg = pastelPurpleBg;
  static const Color tierEpicText = pastelPurpleText;

  static const Color tierLegendBg = pastelYellowBg;
  static const Color tierLegendText = pastelYellowText;

  static const Color tierMythicBg = pastelRedBg;
  static const Color tierMythicText = pastelRedText;

  static const Color tierCollectorBg = ink;
  static const Color tierCollectorText = surface;

  // ----- Dark Theme Palette -----
  static const Color canvasDefaultDark = Color(0xFF17171A);
  static const Color canvasSurfaceDark = Color(0xFF1D1D1F);
  static const Color surfaceDark = Color(0xFF232325);

  static const Color textDark = Color(0xFFF2F1EE);
  static const Color textSoftDark = Color(0xFFCFCDC7);
  static const Color mutedDark = Color(0xFF8F8D86);
  static const Color borderDark = Color(0xFF2E2E2C);

  static const Color forestDark = Color(0xFF7FB069);
  static const Color emeraldDark = Color(0xFF6FBE95);

  static const Color pastelRedBgDark = Color(0xFF3A2323);
  static const Color pastelRedTextDark = Color(0xFFF2A9A6);

  static const Color pastelBlueBgDark = Color(0xFF1E2E38);
  static const Color pastelBlueTextDark = Color(0xFF8FC7EC);

  static const Color pastelGreenBgDark = Color(0xFF223328);
  static const Color pastelGreenTextDark = Color(0xFF93D2A8);

  static const Color pastelYellowBgDark = Color(0xFF3A3120);
  static const Color pastelYellowTextDark = Color(0xFFE8C878);

  static const Color pastelPurpleBgDark = Color(0xFF2B2738);
  static const Color pastelPurpleTextDark = Color(0xFFBBA8E8);

  static const Color pastelGrayBgDark = Color(0xFF29292A);
  static const Color pastelGrayTextDark = Color(0xFFB8B6B0);
}
