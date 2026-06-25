import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';

class AppTheme {
  const AppTheme._();

  static const String cairoFontFamily = 'Cairo';

  static ThemeData dark() {
    WidgetsFlutterBinding.ensureInitialized();

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.crimson,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.crimson,
      secondary: AppColors.warning,
      surface: AppColors.surface,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _textTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      cardTheme: CardThemeData(
        color: AppColors.elevatedSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderRadiusLg,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.crimson,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.disabled,
          disabledForegroundColor: AppColors.disabledText,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusLg),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.crimson),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusLg),
          disabledForegroundColor: AppColors.disabledText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.crimson),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.elevatedSurface,
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderRadiusLg,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderRadiusLg,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderRadiusLg,
          borderSide: const BorderSide(color: AppColors.crimson, width: 1.4),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.crimson,
        thumbColor: AppColors.crimson,
        inactiveTrackColor: AppColors.border,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.elevatedSurface,
        side: const BorderSide(color: AppColors.borderSubtle),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusSm),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        selectedColor: AppColors.crimsonSubtle,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.elevatedSurface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderRadiusXl,
          side: const BorderSide(color: AppColors.border),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.elevatedSurface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusMd),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 0.5,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.crimson,
      ),
    );
  }

  static TextTheme _textTheme() {
    return const TextTheme(
      displaySmall: TextStyle(
        color: AppColors.textPrimary,
        fontFamily: cairoFontFamily,
        fontSize: 36,
        fontWeight: FontWeight.w800,
      ),
      headlineLarge: TextStyle(
        color: AppColors.textPrimary,
        fontFamily: cairoFontFamily,
        fontSize: 36,
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: TextStyle(
        color: AppColors.textPrimary,
        fontFamily: cairoFontFamily,
        fontSize: 30,
        fontWeight: FontWeight.w800,
      ),
      headlineSmall: TextStyle(
        color: AppColors.textPrimary,
        fontFamily: cairoFontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: TextStyle(
        color: AppColors.textPrimary,
        fontFamily: cairoFontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: AppColors.textPrimary,
        fontFamily: cairoFontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: AppColors.textSecondary,
        fontFamily: cairoFontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: AppColors.textPrimary,
        fontFamily: cairoFontFamily,
        fontSize: 16,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textSecondary,
        fontFamily: cairoFontFamily,
        fontSize: 14,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        color: AppColors.textMuted,
        fontFamily: cairoFontFamily,
        fontSize: 12,
      ),
      labelLarge: TextStyle(
        color: AppColors.textPrimary,
        fontFamily: cairoFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      labelSmall: TextStyle(
        color: AppColors.textSecondary,
        fontFamily: cairoFontFamily,
        fontSize: 11,
      ),
    );
  }
}
