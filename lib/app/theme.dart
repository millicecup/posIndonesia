import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const orange = Color(0xFFD85724);
  static const orangeLight = Color(0xFFFBE6D9);
  static const white = Color(0xFFFFFFFF);
  static const darkGrey = Color(0xFF203344);
  static const grey = Color(0xFF667580);
  static const lightGrey = Color(0xFFECE8E1);
  static const cream = Color(0xFFFAF7F2);
  static const teal = Color(0xFF287B71);
  static const success = teal;
  static const warning = Color(0xFFA86813);
  static const danger = Color(0xFFB53636);
}

class AppTheme {
  AppTheme._();
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.orange,
      primary: AppColors.orange,
      secondary: AppColors.teal,
      surface: AppColors.white,
      onSurface: AppColors.darkGrey,
      onPrimary: AppColors.white,
      outline: AppColors.lightGrey,
    );
    final base = ThemeData(
        useMaterial3: true, colorScheme: scheme, fontFamily: 'PlusJakartaSans');
    final text = base.textTheme.copyWith(
      headlineLarge: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 30,
          fontWeight: FontWeight.w600,
          height: 1.25,
          color: AppColors.darkGrey),
      headlineMedium: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 26,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: AppColors.darkGrey),
      titleLarge: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 1.35,
          color: AppColors.darkGrey),
      titleMedium: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 19,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: AppColors.darkGrey),
      titleSmall: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.4,
          color: AppColors.darkGrey),
      bodyLarge: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 16,
          height: 1.6,
          color: AppColors.darkGrey),
      bodyMedium: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 16,
          height: 1.6,
          color: AppColors.darkGrey),
      bodySmall: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 13,
          height: 1.5,
          color: AppColors.grey),
    );
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: AppColors.cream,
      appBarTheme: AppBarTheme(
          backgroundColor: AppColors.cream,
          foregroundColor: AppColors.darkGrey,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: text.titleMedium),
      cardTheme: CardThemeData(
          color: AppColors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.lightGrey))),
      dividerTheme:
          const DividerThemeData(color: AppColors.lightGrey, thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
          height: 68,
          elevation: 0,
          backgroundColor: AppColors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: AppColors.orangeLight,
          labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 12,
              fontWeight: s.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: s.contains(WidgetState.selected)
                  ? AppColors.orange
                  : AppColors.grey))),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(64, 50),
              textStyle: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
              shape: shape)),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              minimumSize: const Size(64, 50),
              shape: shape,
              textStyle: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700))),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkGrey,
              minimumSize: const Size(64, 48),
              side: const BorderSide(color: AppColors.lightGrey),
              shape: shape,
              textStyle: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600))),
      chipTheme: ChipThemeData(
          backgroundColor: AppColors.orangeLight,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          labelStyle: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 12,
              color: AppColors.darkGrey)),
      bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.cream,
          surfaceTintColor: Colors.transparent,
          showDragHandle: true),
      dialogTheme: DialogThemeData(
          backgroundColor: AppColors.cream,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
      snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.darkGrey,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    );
  }
}
