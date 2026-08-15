import 'package:flutter/painting.dart';

abstract final class AppColors {
  AppColors._();

  // ----- Light -----

  static const Color canvasDefault = Color(0xFFF1F3F5);
  static const Color canvasSurface = Color(0xFFFBFBFD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color forest = Color(0xFF2D4F1E);
  static const Color emerald = Color(0xFF2D6A4F);

  // Text
  static const Color ink = Color(0xFF111111);
  static const Color inkSoft = Color(0xFF2F3437);
  static const Color muted = Color(0xFF787774);
  static const Color border = Color(0xFFEAEAEA);

  // Accent
  static const Color pastelRedBg = Color(0xFFFDEBEC);
  static const Color pastelRedText = Color(0xFF9F2F2D);

  static const Color pastelBlueBg = Color(0xFFE1F3FE);
  static const Color pastelBlueText = Color(0xFF1F6C9F);

  static const Color pastelGreenBg = Color(0xFFEDF3EC);
  static const Color pastelGreenText = Color(0xFF346538);

  static const Color pastelYellowBg = Color(0xFFFBF3DB);
  static const Color pastelYellowText = Color(0xFF956400);

  static const Color pastelPurpleBg = Color(0xFFEFEBF7);
  static const Color pastelPurpleText = Color(0xFF5B4B8A);

  static const Color pastelGrayBg = Color(0xFFF0F0EF);
  static const Color pastelGrayText = Color(0xFF6B6B67);

  // Tier
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

  // ----- Dark -----

  static const Color canvasDefaultDark = Color(0xFF17171A);
  static const Color canvasSurfaceDark = Color(0xFF1D1D1F);
  static const Color surfaceDark = Color(0xFF232325);

  // Text
  static const Color inkDark = Color(0xFFF2F1EE);
  static const Color inkSoftDark = Color(0xFFCFCDC7);
  static const Color mutedDark = Color(0xFF8F8D86);
  static const Color borderDark = Color(0xFF2E2E2C);

  static const Color forestDark = Color(0xFF7FB069);
  static const Color emeraldDark = Color(0xFF6FBE95);

  // Accent
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

  // Tier
  static const Color tierNormalBgDark = pastelGrayBgDark;
  static const Color tierNormalTextDark = pastelGrayTextDark;

  static const Color tierEliteBgDark = pastelGreenBgDark;
  static const Color tierEliteTextDark = pastelGreenTextDark;

  static const Color tierSpecialBgDark = pastelBlueBgDark;
  static const Color tierSpecialTextDark = pastelBlueTextDark;

  static const Color tierEpicBgDark = pastelPurpleBgDark;
  static const Color tierEpicTextDark = pastelPurpleTextDark;

  static const Color tierLegendBgDark = pastelYellowBgDark;
  static const Color tierLegendTextDark = pastelYellowTextDark;

  static const Color tierMythicBgDark = pastelRedBgDark;
  static const Color tierMythicTextDark = pastelRedTextDark;

  static const Color tierCollectorBgDark = inkDark;
  static const Color tierCollectorTextDark = canvasDefaultDark;
}
