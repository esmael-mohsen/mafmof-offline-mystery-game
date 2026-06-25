import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  const AppShadows._();

  static BoxShadow crimsonGlow({
    double blurRadius = 16,
    double spreadRadius = 0,
    Offset offset = Offset.zero,
  }) =>
      BoxShadow(
        color: AppColors.crimsonGlow.withValues(alpha: 0.35),
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
        offset: offset,
      );

  static BoxShadow subtle({
    double blurRadius = 8,
    double spreadRadius = 0,
    Offset offset = const Offset(0, 2),
  }) =>
      BoxShadow(
        color: AppColors.background.withValues(alpha: 0.6),
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
        offset: offset,
      );

  static BoxShadow deep({
    double blurRadius = 20,
    double spreadRadius = 2,
    Offset offset = const Offset(0, 4),
  }) =>
      BoxShadow(
        color: AppColors.background.withValues(alpha: 0.8),
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
        offset: offset,
      );

  static BoxDecoration crimsonGlowDecoration({
    double borderRadius = 12,
    double blurRadius = 16,
  }) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          crimsonGlow(blurRadius: blurRadius),
        ],
      );
}
