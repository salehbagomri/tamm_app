import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────
/// Tamm Design Token System — AppSpacing
/// ─────────────────────────────────────────────────────
/// نظام التصميم الموحد لتطبيق تمّ
///
/// القاعدة: استخدم دائماً هذه الثوابت بدلاً من الأرقام المباشرة
/// ❌ padding: EdgeInsets.all(16)
/// ✅ padding: AppSpacing.cardPadding
/// ─────────────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();

  // ─── Base Scale (4pt grid) ──────────────────────────
  // القياس الأساسي: كل وحدة = 4 نقاط
  static const double none = 0;
  static const double xs = 4; // فاصل دقيق جداً — بين الشارات والنصوص
  static const double sm = 8; // فاصل صغير — بين الأيقونات والعناصر
  static const double sm2 = 12; // فاصل صغير+ — بين بطاقات القائمة
  static const double md = 16; // فاصل متوسط — padding داخل البطاقات
  static const double lg = 24; // فاصل كبير — بين الأقسام
  static const double xl = 32; // فاصل كبير+ — بين الأقسام الرئيسية
  static const double xxl = 48; // فاصل ضخم — للصفحات الفارغة

  // ─── Semantic Spacing Tokens ─────────────────────────
  // فاصل دلالي — مرتبط بالمعنى وليس بالرقم المجرد

  /// المسافة بين العناصر المجاورة (icon & text)
  static const double itemGap = sm;

  /// المسافة بين البطاقات في القوائم
  static const double cardGap = sm2;

  /// المسافة بين الأقسام الرئيسية في الشاشة
  static const double sectionGap = xl;

  /// المسافة الداخلية للصفحة من الجانبين
  static const double pageHorizontal = md;

  /// المسافة الداخلية للصفحة من الأعلى والأسفل
  static const double pageVertical = sm2;

  // ─── Padding Presets ─────────────────────────────────
  // قوالب padding جاهزة للاستخدام المتكرر

  /// padding الصفحات الرئيسية
  static const pagePadding = EdgeInsets.symmetric(
    horizontal: pageHorizontal,
    vertical: pageVertical,
  );

  /// padding البطاقات (TammCard)
  static const cardPadding = EdgeInsets.all(md);

  /// padding البطاقات الصغيرة
  static const cardPaddingSm = EdgeInsets.all(sm2);

  /// padding الأزرار الصغيرة
  static const buttonPaddingSm = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  /// padding الأزرار الكبيرة
  static const buttonPaddingLg = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  /// padding الأيقونات الدائرية (Header Icons)
  static const iconCirclePadding = EdgeInsets.all(10);

  /// padding الشارات (Badges, Tags)
  static const badgePadding = EdgeInsets.symmetric(
    horizontal: xs + 2,
    vertical: xs / 2,
  );

  /// padding الـ BottomSheet
  static const sheetPadding = EdgeInsets.fromLTRB(md, lg, md, lg);

  /// padding الـ Dialog
  static const dialogPadding = EdgeInsets.all(lg);

  // ─── Border Radius ────────────────────────────────────
  // قيم الحواف الدائرية

  static const radiusXs = BorderRadius.all(Radius.circular(4));
  static const radiusSm = BorderRadius.all(Radius.circular(8));
  static const radius = BorderRadius.all(Radius.circular(12)); // الافتراضي
  static const radiusLg = BorderRadius.all(Radius.circular(16));
  static const radiusXl = BorderRadius.all(Radius.circular(20));
  static const radiusFull = BorderRadius.all(Radius.circular(100)); // دائري تام

  // ─── Radius as double (for ClipRRect, etc.) ──────────
  static const double radiusXsValue = 4;
  static const double radiusSmValue = 8;
  static const double radiusValue = 12;
  static const double radiusLgValue = 16;
  static const double radiusXlValue = 20;
  static const double radiusFullValue = 100;

  // ─── Icon Sizes ───────────────────────────────────────
  // أحجام الأيقونات الموحدة

  static const double iconXs = 16; // أيقونات inline داخل النص
  static const double iconSm = 20; // أيقونات الـ AppBar الصغيرة
  static const double iconMd = 24; // الحجم الافتراضي للأيقونات
  static const double iconLg = 32; // أيقونات بارزة
  static const double iconXl = 40; // أيقونات Empty State
  static const double iconXxl = 48; // أيقونات كبيرة جداً

  // ─── Component Sizes ──────────────────────────────────
  // أحجام ثابتة للمكونات المعيارية

  static const double buttonHeight = 52; // ارتفاع الزر الأساسي
  static const double buttonHeightSm = 40; // ارتفاع الزر الصغير
  static const double inputHeight = 52; // ارتفاع حقل الإدخال
  static const double appBarHeight = 56; // ارتفاع الـ AppBar
  static const double bottomNavHeight = 68; // ارتفاع الـ BottomNavigationBar
  static const double headerIconSize =
      44; // حجم الأيقونة الدائرية في الـ Header
  static const double avatarSm = 36; // صورة المستخدم الصغيرة
  static const double avatarMd = 48; // صورة المستخدم المتوسطة
  static const double avatarLg = 72; // صورة المستخدم الكبيرة
  static const double productCardWidth =
      160; // عرض بطاقة المنتج في القائمة الأفقية
  static const double productCardHeight =
      200; // ارتفاع بطاقة المنتج في القائمة الأفقية
  static const double shimmerRadius = 8; // حواف الـ Shimmer

  // ─── SizedBox Helpers ────────────────────────────────
  // مساعدات جاهزة لاستخدام مكثف

  static const Widget gapXs = SizedBox(height: xs);
  static const Widget gapSm = SizedBox(height: sm);
  static const Widget gapSm2 = SizedBox(height: sm2);
  static const Widget gapMd = SizedBox(height: md);
  static const Widget gapLg = SizedBox(height: lg);
  static const Widget gapXl = SizedBox(height: xl);
  static const Widget gapXxl = SizedBox(height: xxl);

  static const Widget hGapXs = SizedBox(width: xs);
  static const Widget hGapSm = SizedBox(width: sm);
  static const Widget hGapSm2 = SizedBox(width: sm2);
  static const Widget hGapMd = SizedBox(width: md);
  static const Widget hGapLg = SizedBox(width: lg);
}
