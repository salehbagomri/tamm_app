import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import 'tamm_colors.dart';

class AppTheme {
  AppTheme._();

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    extensions: const <ThemeExtension<dynamic>>[
      TammColors.dark,
    ],
    scaffoldBackgroundColor: TammColors.dark.bgPrimary,
    primaryColor: TammColors.dark.bluePrimary,
    colorScheme: ColorScheme.dark(
      primary: TammColors.dark.bluePrimary,
      secondary: TammColors.dark.blueLight,
      surface: TammColors.dark.bgSurface,
      error: TammColors.dark.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: TammColors.dark.textPrimary,
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.harmattanTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: TammColors.dark.textPrimary,
      displayColor: TammColors.dark.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: TammColors.dark.bgPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.harmattan(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: TammColors.dark.textPrimary,
      ),
      iconTheme: IconThemeData(color: TammColors.dark.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: TammColors.dark.bgSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: TammColors.dark.border, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: TammColors.dark.bluePrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.harmattan(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TammColors.dark.bluePrimary,
        minimumSize: const Size(double.infinity, 52),
        side: BorderSide(color: TammColors.dark.bluePrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.harmattan(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TammColors.dark.bgSurface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: TammColors.dark.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: TammColors.dark.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: TammColors.dark.bluePrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: TammColors.dark.error),
      ),
      hintStyle: GoogleFonts.harmattan(
        color: TammColors.dark.textFaint,
        fontSize: 14,
      ),
      labelStyle: GoogleFonts.harmattan(
        color: TammColors.dark.textSecond,
        fontSize: 14,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: TammColors.dark.bgSurface,
      selectedItemColor: TammColors.dark.bluePrimary,
      unselectedItemColor: TammColors.dark.textFaint,
      type: BottomNavigationBarType.fixed,
    ),
    dividerTheme: DividerThemeData(color: TammColors.dark.border, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: TammColors.dark.bgSurface2,
      contentTextStyle: GoogleFonts.harmattan(color: TammColors.dark.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
  );

  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    extensions: const <ThemeExtension<dynamic>>[
      TammColors.light,
    ],
    scaffoldBackgroundColor: TammColors.light.bgPrimary,
    primaryColor: TammColors.light.bluePrimary,
    colorScheme: ColorScheme.light(
      primary: TammColors.light.bluePrimary,
      secondary: TammColors.light.blueLight,
      surface: TammColors.light.bgSurface,
      error: TammColors.light.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: TammColors.light.textPrimary,
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.harmattanTextTheme(ThemeData.light().textTheme).apply(
      bodyColor: TammColors.light.textPrimary,
      displayColor: TammColors.light.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: TammColors.light.bgPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.harmattan(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: TammColors.light.textPrimary,
      ),
      iconTheme: IconThemeData(color: TammColors.light.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: TammColors.light.bgSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: TammColors.light.border, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: TammColors.light.bluePrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.harmattan(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TammColors.light.bluePrimary,
        minimumSize: const Size(double.infinity, 52),
        side: BorderSide(color: TammColors.light.bluePrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.harmattan(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TammColors.light.bgSurface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: TammColors.light.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: TammColors.light.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: TammColors.light.bluePrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: TammColors.light.error),
      ),
      hintStyle: GoogleFonts.harmattan(
        color: TammColors.light.textFaint,
        fontSize: 14,
      ),
      labelStyle: GoogleFonts.harmattan(
        color: TammColors.light.textSecond,
        fontSize: 14,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: TammColors.light.bgSurface,
      selectedItemColor: TammColors.light.bluePrimary,
      unselectedItemColor: TammColors.light.textFaint,
      type: BottomNavigationBarType.fixed,
    ),
    dividerTheme: DividerThemeData(color: TammColors.light.border, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: TammColors.light.bgSurface2,
      contentTextStyle: GoogleFonts.harmattan(color: TammColors.light.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
