import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppGradients {
  const AppGradients._();

  static const LinearGradient screen = AppColors.cinematicGradient;

  static const RadialGradient redAtmosphere = RadialGradient(
    center: Alignment.topRight,
    radius: 1.15,
    colors: [
      Color(0x3DE21D2F),
      Color(0x12080A0F),
      AppColors.background,
    ],
    stops: [0, 0.42, 1],
  );

  static const LinearGradient imageScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.25, 0.62, 1],
    colors: [
      Color(0x00000000),
      AppColors.cardOverlayLight,
      AppColors.cardOverlay,
    ],
  );

  static const LinearGradient crimsonButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.crimson,
      AppColors.deepCrimson,
    ],
  );
}
