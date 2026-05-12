import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────────────
/// Tamm Design Token System — AppTextStyles
/// ─────────────────────────────────────────────────────
/// نظام الخطوط الموحد لتطبيق تمّ
///
/// الاستخدام الصح:
/// ✅ GoogleFonts.alexandria(fontSize: AppTextStyles.fontSizeLg, fontWeight: AppTextStyles.bold, color: context.colors.textPrimary)
/// ✅ AppTextStyles.withColor(AppTextStyles.h2, context.colors.textPrimary)
///
/// ⚠️ تنبيه: لا تستخدم AppTextStyles مباشرة مع ألوان ثابتة — استخدم context.colors دائماً
/// ─────────────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  // ─── Font Sizes ──────────────────────────────────────
  static const double fontSizeXs = 11; // ملاحظات دقيقة، شارات
  static const double fontSizeSm = 12; // Caption, تواريخ
  static const double fontSizeSm2 = 13; // نصوص ثانوية صغيرة
  static const double fontSizeMd = 14; // نصوص ثانوية، labels
  static const double fontSizeMd2 = 15; // نصوص عادية صغيرة
  static const double fontSizeBase = 16; // النص الأساسي
  static const double fontSizeLg = 18; // نصوص مميزة
  static const double fontSizeXl = 20; // عناوين الأقسام
  static const double fontSizeXl2 = 22; // عناوين فرعية
  static const double fontSizeH3 = 24; // عناوين المستوى الثالث
  static const double fontSizeH2 = 26; // عناوين الشاشات
  static const double fontSizeH1 = 32; // عناوين رئيسية كبيرة

  // ─── Font Weights ────────────────────────────────────
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // ─── Line Heights ────────────────────────────────────
  static const double lineHeightNormal = 1.4;
  static const double lineHeightTight = 1.2;
  static const double lineHeightLoose = 1.6;

  // ─── Style Builders (context-aware) ─────────────────
  // استخدم هذه الدوال لإنشاء TextStyle مع لون context

  static TextStyle h1(Color color) => GoogleFonts.alexandria(
    fontSize: fontSizeH1,
    fontWeight: bold,
    color: color,
  );

  static TextStyle h2(Color color) => GoogleFonts.alexandria(
    fontSize: fontSizeH2,
    fontWeight: bold,
    color: color,
  );

  static TextStyle h3(Color color) => GoogleFonts.alexandria(
    fontSize: fontSizeH3,
    fontWeight: semiBold,
    color: color,
  );

  static TextStyle sectionTitle(Color color) => GoogleFonts.alexandria(
    fontSize: fontSizeXl,
    fontWeight: semiBold,
    color: color,
  );

  static TextStyle cardTitle(Color color) => GoogleFonts.alexandria(
    fontSize: fontSizeLg,
    fontWeight: semiBold,
    color: color,
  );

  static TextStyle body(Color color) => GoogleFonts.alexandria(
    fontSize: fontSizeBase,
    fontWeight: regular,
    color: color,
  );

  static TextStyle bodySmall(Color color) => GoogleFonts.alexandria(
    fontSize: fontSizeMd,
    fontWeight: regular,
    color: color,
  );

  static TextStyle label(Color color) => GoogleFonts.alexandria(
    fontSize: fontSizeMd,
    fontWeight: semiBold,
    color: color,
  );

  static TextStyle caption(Color color) => GoogleFonts.alexandria(
    fontSize: fontSizeSm,
    fontWeight: regular,
    color: color,
  );

  static TextStyle price(Color color) => GoogleFonts.alexandria(
    fontSize: fontSizeXl,
    fontWeight: bold,
    color: color,
  );

  static TextStyle priceSm(Color color) => GoogleFonts.alexandria(
    fontSize: fontSizeLg,
    fontWeight: bold,
    color: color,
  );

  static TextStyle badge(Color color) => GoogleFonts.alexandria(
    fontSize: fontSizeXs,
    fontWeight: bold,
    color: color,
  );

  static TextStyle button(Color color) => GoogleFonts.alexandria(
    fontSize: fontSizeBase,
    fontWeight: semiBold,
    color: color,
  );

  static TextStyle buttonSm(Color color) => GoogleFonts.alexandria(
    fontSize: fontSizeMd,
    fontWeight: semiBold,
    color: color,
  );

  static TextStyle link(Color color) => GoogleFonts.alexandria(
    fontSize: fontSizeBase,
    fontWeight: regular,
    color: color,
    decoration: TextDecoration.underline,
  );
}
