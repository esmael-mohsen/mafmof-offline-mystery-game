import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const String cairoFontFamily = 'Cairo';
  static const String amiriFontFamily = 'Amiri';
  static const String arefRuqaaInkFontFamily = 'Aref Ruqaa Ink';

  static TextStyle heroTitle(BuildContext context) =>
      Theme.of(context).textTheme.headlineLarge!.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            height: 1.1,
          );

  static TextStyle heroSignatureTitle(BuildContext context) =>
      (Theme.of(context).textTheme.displaySmall ?? const TextStyle()).copyWith(
        color: AppColors.textPrimary,
        fontFamily: arefRuqaaInkFontFamily,
        fontWeight: FontWeight.w700,
        height: 1.15,
      );

  static TextStyle sectionAmiriTitle(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium!.copyWith(
            color: AppColors.textPrimary,
            fontFamily: amiriFontFamily,
            fontWeight: FontWeight.w700,
            height: 1.15,
          );

  static TextStyle screenTitle(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium!.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          );

  static TextStyle sectionTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          );

  static TextStyle cardTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          );

  static TextStyle subsectionTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall!.copyWith(
            color: AppColors.crimson,
            fontWeight: FontWeight.w600,
          );

  static TextStyle bodyPrimary(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: AppColors.textPrimary,
            height: 1.5,
          );

  static TextStyle bodySecondary(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: AppColors.textSecondary,
            height: 1.45,
          );

  static TextStyle clueText(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            height: 1.55,
          );

  static TextStyle characterName(BuildContext context) =>
      Theme.of(context).textTheme.headlineSmall!.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          );

  static TextStyle roleLabel(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall!.copyWith(
            color: AppColors.crimson,
            fontWeight: FontWeight.w600,
          );

  static TextStyle buttonLabel(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge!.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          );

  static TextStyle caption(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!.copyWith(
            color: AppColors.textMuted,
          );

  static TextStyle tag(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall!.copyWith(
            color: AppColors.textSecondary,
          );

  static TextStyle timerDisplay(BuildContext context) =>
      Theme.of(context).textTheme.displaySmall!.copyWith(
            fontWeight: FontWeight.w800,
          );
}
