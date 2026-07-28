import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color bgDeep = Color(0xFF090909);
  static const Color bgSurface = Color(0xFF1C1917);
  static const Color bgCard = Color(0xFF292524);
  static const Color bgCardHover = Color(0xFF44403C);
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentHover = Color(0xFFD97706);
  static const Color accentGlow = Color(0x40F59E0B);
  static const Color borderSubtle = Color(0x26F59E0B);
  static const Color textPrimary = Color(0xFFFAFAF9);
  static const Color textSecondary = Color(0xFFA8A29E);
  static const Color textMuted = Color(0xFF78716C);
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, danger],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppSizes {
  AppSizes._();

  static const double borderRadiusCard = 16.0;
  static const double borderRadiusPill = 50.0;
  static const double channelLogoSize = 56.0;
  static const double channelLogoSizeDesktop = 52.0;
  static const double gridMaxExtent = 80.0;
  static const double controlsBlur = 12.0;
  static const double panelWidth = 325.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDeep,
      primaryColor: AppColors.accent,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accentHover,
        surface: AppColors.bgSurface,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      fontFamily: 'sans-serif',
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusCard),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusPill),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusPill),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 20),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.white.withOpacity(0.04),
    );
  }
}
