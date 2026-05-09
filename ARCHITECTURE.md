# Tamm App — Architecture & Development Standards
> **يجب قراءة هذا الملف قبل أي إضافة أو تعديل**

## Quick Reference

### إضافة شاشة جديدة (Checklist)
- [ ] Model في `shared/models/`
- [ ] Repository في `shared/repositories/` مع AppException
- [ ] Provider في `shared/providers/`
- [ ] Screen تتبع هيكل Section 4 (Scaffold → SafeArea → ResponsiveWrapper → .when)
- [ ] Route في `app_router.dart` (Shell أم Root؟)
- [ ] dart format قبل commit

### الـ Widget الصح لكل حالة
| الحالة | الويدجت |
|--------|---------|
| تحميل | `TammLoading()` |
| خطأ | `ErrorStateWidget(message, onRetry)` |
| فارغ | `TammEmptyState(icon, message)` |
| بطاقة | `TammCard(child)` |
| زر | `TammButton(label, onPressed)` |
| AppBar | `TammAppBar(title)` |

---

## Design Token System

### AppSpacing — المسافات والأبعاد (`lib/core/constants/app_spacing.dart`)

**القياس الأساسي (4pt grid):**
| Token | Value | الاستخدام |
|-------|-------|-----------|
| `AppSpacing.xs` | 4 | بين الشارات والنصوص |
| `AppSpacing.sm` | 8 | بين الأيقونات والعناصر — `itemGap` |
| `AppSpacing.sm2` | 12 | بين البطاقات في القوائم — `cardGap` |
| `AppSpacing.md` | 16 | padding البطاقات — `pageHorizontal` |
| `AppSpacing.lg` | 24 | بين الأقسام |
| `AppSpacing.xl` | 32 | بين الأقسام الرئيسية — `sectionGap` |
| `AppSpacing.xxl` | 48 | صفحات فارغة |

**Padding Presets:**
```dart
AppSpacing.pagePadding      // الصفحات الرئيسية
AppSpacing.cardPadding      // البطاقات (16)
AppSpacing.cardPaddingSm    // البطاقات الصغيرة (12)
AppSpacing.iconCirclePadding // الأيقونات الدائرية (10)
AppSpacing.sheetPadding     // BottomSheet
AppSpacing.dialogPadding    // Dialog
```

**Border Radius:**
```dart
AppSpacing.radiusXs    // 4
AppSpacing.radiusSm    // 8
AppSpacing.radius      // 12 ← الافتراضي
AppSpacing.radiusLg    // 16
AppSpacing.radiusXl    // 20
AppSpacing.radiusFull  // 100 (دائري)
```

**أحجام الأيقونات:**
```dart
AppSpacing.iconSm = 20  // AppBar
AppSpacing.iconMd = 24  // افتراضي ← استخدم هذا دائماً
AppSpacing.iconLg = 32  // بارز
AppSpacing.iconXl = 40  // Empty State
```

**SizedBox Helpers:**
```dart
AppSpacing.gapSm    // SizedBox(height: 8)
AppSpacing.gapSm2   // SizedBox(height: 12)
AppSpacing.gapMd    // SizedBox(height: 16)
AppSpacing.gapLg    // SizedBox(height: 24)
AppSpacing.hGapSm   // SizedBox(width: 8)
AppSpacing.hGapSm2  // SizedBox(width: 12)
```

### AppTextStyles — الخطوط (`lib/core/constants/app_text_styles.dart`)

**Font Sizes:**
```dart
AppTextStyles.fontSizeXs   = 11  // شارات
AppTextStyles.fontSizeSm   = 12  // Caption
AppTextStyles.fontSizeMd   = 14  // Labels
AppTextStyles.fontSizeBase = 16  // نص أساسي
AppTextStyles.fontSizeLg   = 18  // نص مميز
AppTextStyles.fontSizeXl   = 20  // عناوين أقسام
AppTextStyles.fontSizeH2   = 26  // عناوين شاشات
```

**Font Weights:**
```dart
AppTextStyles.regular  = w400
AppTextStyles.semiBold = w600
AppTextStyles.bold     = w700
```

**Style Builders (تستقبل لون context):**
```dart
AppTextStyles.h2(context.colors.textPrimary)
AppTextStyles.sectionTitle(context.colors.textPrimary)
AppTextStyles.body(context.colors.textSecond)
AppTextStyles.caption(context.colors.textFaint)
AppTextStyles.price(context.colors.blueSky)
AppTextStyles.label(context.colors.textPrimary)
```

### القاعدة الذهبية
```
❌ ممنوع                    ✅ الصح
────────────────────────────────────────────────
EdgeInsets.all(16)         → AppSpacing.cardPadding
EdgeInsets.all(12)         → AppSpacing.cardPaddingSm
SizedBox(height: 8)        → AppSpacing.gapSm
SizedBox(height: 12)       → AppSpacing.gapSm2
SizedBox(width: 8)         → AppSpacing.hGapSm
fontSize: 16               → AppTextStyles.fontSizeBase
FontWeight.w600            → AppTextStyles.semiBold
Radius.circular(12)        → AppSpacing.radiusValue
BorderRadius.all(R.c(12))  → AppSpacing.radius
color: Colors.blue         → context.colors.bluePrimary
```

---

### الـ Colors
```dart
context.colors.textPrimary / textSecond / textFaint
context.colors.bgPrimary / bgSurface / bgSurface2
context.colors.bluePrimary / blueSky / blueLight
context.colors.error / success / warning
```

### Navigation
```dart
context.push(...)  // شاشة فرعية (يرجع)
context.pop()      // رجوع
context.go(...)    // تنقل بين التبويبات فقط
```

### Shell vs Root Route
- **داخل Shell**: Bottom Nav يظهر — للتبويبات الرئيسية
- **Root (parentNavigatorKey: _rootNavigatorKey)**: بدون Bottom Nav — للتفاصيل والشاشات المستقلة

### نمط الـ Error (إلزامي)
```dart
error: (e, _) => ErrorStateWidget(
  message: e is AppException ? e.message : 'حدث خطأ',
  onRetry: () => ref.invalidate(theProvider),
),
```

---
للتفاصيل الكاملة:
- `C:\Users\SALEH\.gemini\antigravity\knowledge\tamm_app_standards\artifacts\standards.md`
- `C:\Users\SALEH\.gemini\antigravity\knowledge\tamm_app_standards\artifacts\design_tokens.md`

