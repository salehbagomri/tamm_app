import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Extension to allow context.colors.bgPrimary instead of Theme.of(context).extension<TammColors>()!
extension TammThemeContext on BuildContext {
  TammColors get colors => Theme.of(this).extension<TammColors>()!;
}

/// Dynamic Colors for Light and Dark modes
class TammColors extends ThemeExtension<TammColors> {
  final Color bgPrimary;
  final Color bgSurface;
  final Color bgSurface2;
  final Color border;

  final Color blueDark;
  final Color blueMid;
  final Color bluePrimary;
  final Color blueLight;
  final Color blueSky;

  final Color textPrimary;
  final Color textSecond;
  final Color textFaint;

  final Color success;
  final Color error;
  final Color warning;

  const TammColors({
    required this.bgPrimary,
    required this.bgSurface,
    required this.bgSurface2,
    required this.border,
    required this.blueDark,
    required this.blueMid,
    required this.bluePrimary,
    required this.blueLight,
    required this.blueSky,
    required this.textPrimary,
    required this.textSecond,
    required this.textFaint,
    required this.success,
    required this.error,
    required this.warning,
  });

  /// The Dark Theme definition (Matches our original AppColors exactly)
  static const dark = TammColors(
    bgPrimary: AppColors.bgPrimary,
    bgSurface: AppColors.bgSurface,
    bgSurface2: AppColors.bgSurface2,
    border: AppColors.border,
    blueDark: AppColors.blueDark,
    blueMid: AppColors.blueMid,
    bluePrimary: AppColors.bluePrimary,
    blueLight: AppColors.blueLight,
    blueSky: AppColors.blueSky,
    textPrimary: AppColors.textPrimary,
    textSecond: AppColors.textSecond,
    textFaint: AppColors.textFaint,
    success: AppColors.success,
    error: AppColors.error,
    warning: AppColors.warning,
  );

  /// The Light Theme definition (Carefully balanced for brightness while keeping the brand identity)
  static const light = TammColors(
    bgPrimary: Color(0xFFF4F7FB),
    bgSurface: Color(0xFFFFFFFF),
    bgSurface2: Color(0xFFEAF0F6),
    border: Color(0xFFD6E2ED),

    // Blues usually look a bit darker on light themes for contrast
    blueDark: Color(0xFF071F36),
    blueMid: Color(0xFF0C427B),
    bluePrimary: AppColors.bluePrimary, // Brand color stays same
    blueLight: AppColors.blueLight,
    blueSky: AppColors.blueSky,

    // Text colors inverted for light background
    textPrimary: Color(0xFF0F1A26),
    textSecond: Color(0xFF4A5D70),
    textFaint: Color(0xFF8BA0B5),

    // Status colors stay the same as they work on both
    success: AppColors.success,
    error: AppColors.error,
    warning: AppColors.warning,
  );

  @override
  ThemeExtension<TammColors> copyWith({
    Color? bgPrimary,
    Color? bgSurface,
    Color? bgSurface2,
    Color? border,
    Color? blueDark,
    Color? blueMid,
    Color? bluePrimary,
    Color? blueLight,
    Color? blueSky,
    Color? textPrimary,
    Color? textSecond,
    Color? textFaint,
    Color? success,
    Color? error,
    Color? warning,
  }) {
    return TammColors(
      bgPrimary: bgPrimary ?? this.bgPrimary,
      bgSurface: bgSurface ?? this.bgSurface,
      bgSurface2: bgSurface2 ?? this.bgSurface2,
      border: border ?? this.border,
      blueDark: blueDark ?? this.blueDark,
      blueMid: blueMid ?? this.blueMid,
      bluePrimary: bluePrimary ?? this.bluePrimary,
      blueLight: blueLight ?? this.blueLight,
      blueSky: blueSky ?? this.blueSky,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecond: textSecond ?? this.textSecond,
      textFaint: textFaint ?? this.textFaint,
      success: success ?? this.success,
      error: error ?? this.error,
      warning: warning ?? this.warning,
    );
  }

  @override
  ThemeExtension<TammColors> lerp(ThemeExtension<TammColors>? other, double t) {
    if (other is! TammColors) return this;
    return TammColors(
      bgPrimary: Color.lerp(bgPrimary, other.bgPrimary, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgSurface2: Color.lerp(bgSurface2, other.bgSurface2, t)!,
      border: Color.lerp(border, other.border, t)!,
      blueDark: Color.lerp(blueDark, other.blueDark, t)!,
      blueMid: Color.lerp(blueMid, other.blueMid, t)!,
      bluePrimary: Color.lerp(bluePrimary, other.bluePrimary, t)!,
      blueLight: Color.lerp(blueLight, other.blueLight, t)!,
      blueSky: Color.lerp(blueSky, other.blueSky, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecond: Color.lerp(textSecond, other.textSecond, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}
