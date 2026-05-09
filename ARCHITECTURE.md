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

### الـ Colors
```dart
context.colors.textPrimary / textSecond / textFaint
context.colors.bgPrimary / bgSurface / bgSurface2
context.colors.bluePrimary / blueSky / blueLight
context.colors.error / success / warning
```

### الـ Font
```dart
GoogleFonts.harmattan(fontSize: 16, fontWeight: FontWeight.w600, color: ...)
```

### نمط الـ Error (إلزامي)
```dart
error: (e, _) => ErrorStateWidget(
  message: e is AppException ? e.message : 'حدث خطأ',
  onRetry: () => ref.invalidate(theProvider),
),
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

---
للتفاصيل الكاملة: `C:\Users\SALEH\.gemini\antigravity\knowledge\tamm_app_standards\artifacts\standards.md`
