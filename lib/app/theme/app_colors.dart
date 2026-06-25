import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color background = Color(0xFF080A0F);
  static const Color surface = Color(0xFF12151C);
  static const Color elevatedSurface = Color(0xFF191D27);
  static const Color cardDark = Color(0xFF171C23);
  static const Color sectionDark = Color(0xFF161A21);

  static const Color crimson = Color(0xFFE21D2F);
  static const Color deepCrimson = Color(0xFF8F101C);
  static const Color crimsonGlow = Color(0xFFE21D2F);
  static const Color crimsonSubtle = Color(0xFF402326);

  static const Color gold = Color(0xFFD4A843);
  static const Color goldSubtle = Color(0xFF2A1F16);

  static const Color textPrimary = Color(0xFFF7F2EC);
  static const Color textSecondary = Color(0xFFB7ADB0);
  static const Color textMuted = Color(0xFF8A8085);

  static const Color border = Color(0xFF382029);
  static const Color borderSubtle = Color(0xFF252830);

  static const Color danger = Color(0xFFFF4D5F);
  static const Color warning = Color(0xFFFFB3BA);
  static const Color success = Color(0xFF2ECC71);
  static const Color info = Color(0xFF1F3454);

  static const Color disabled = Color(0xFF3A3D45);
  static const Color disabledText = Color(0xFF6A6D75);

  static const Color overlayGradientTop = Color(0xFF12060A);
  static const Color innocentWinSurface = Color(0xFF182321);
  static const Color mafiaWinSurface = Color(0xFF402326);
  static const Color timerWarningSurface = Color(0xFF213127);
  static const Color suspicionChip = Color(0xFF3C2A17);

  static const Color appBarBackground = Color(0xFF0C0E14);
  static const Color appBarRedLine = Color(0xFFE21D2F);
  static const Color dividerRed = Color(0xFF5A1520);
  static const Color cardOverlay = Color(0xD9080A0F);
  static const Color cardOverlayLight = Color(0x4D080A0F);

  static const LinearGradient cinematicGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [overlayGradientTop, background, background],
  );

  static const Color crimsonGlowAlpha12 = Color(0x1FE21D2F);

  static LinearGradient crimsonGlowGradient() => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [crimsonGlowAlpha12, background],
      );
}
