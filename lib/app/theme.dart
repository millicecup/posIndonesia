// lib/app/theme.dart
// Tema oranye-putih-abu gelap sesuai wireframe (PIC: Farella).

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const Color orange = Color(0xFFF26522);
  static const Color orangeLight = Color(0xFFFFE3D3);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkGrey = Color(0xFF333333);
  static const Color grey = Color(0xFF8A8A8A);
  static const Color lightGrey = Color(0xFFF2F2F2);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = Color(0xFFC62828);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.orange,
      primary: AppColors.orange,
      onPrimary: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.darkGrey,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.white,
        centerTitle: false,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.orangeLight,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, color: AppColors.darkGrey),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      // cardTheme sengaja tidak diset: tipenya berubah antar versi Flutter
      // (CardTheme -> CardThemeData). Gaya kartu diatur di PoiCard.
      chipTheme: const ChipThemeData(
        selectedColor: AppColors.orange,
        backgroundColor: AppColors.lightGrey,
        labelStyle: TextStyle(color: AppColors.darkGrey),
        secondaryLabelStyle: TextStyle(color: AppColors.white),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGrey),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkGrey),
        bodyMedium: TextStyle(color: AppColors.darkGrey),
      ),
    );
  }
}
