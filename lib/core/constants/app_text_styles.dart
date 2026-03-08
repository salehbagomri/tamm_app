import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base({
    double size = 16,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? height,
  }) {
    return GoogleFonts.harmattan(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  // العناوين
  static final h1 = _base(size: 32, weight: FontWeight.w700);
  static final h2 = _base(size: 26, weight: FontWeight.w700);
  static final h3 = _base(size: 22, weight: FontWeight.w600);
  static final h4 = _base(size: 18, weight: FontWeight.w600);

  // النصوص
  static final bodyLarge = _base(size: 18);
  static final body = _base(size: 16);
  static final bodySmall = _base(size: 14);

  // ثانوي
  static final caption = _base(size: 12, color: AppColors.textSecond);
  static final label = _base(size: 14, weight: FontWeight.w600);

  // خاص
  static final price = _base(
    size: 20,
    weight: FontWeight.w700,
    color: AppColors.blueSky,
  );
  static final tamm = _base(
    size: 40,
    weight: FontWeight.w700,
    color: AppColors.success,
  );
  static final link = _base(size: 16, color: AppColors.blueLight);

  // أزرار
  static final button = _base(
    size: 16,
    weight: FontWeight.w600,
    color: const Color(0xFFFFFFFF),
  );
  static final buttonSmall = _base(
    size: 14,
    weight: FontWeight.w600,
    color: const Color(0xFFFFFFFF),
  );
}
