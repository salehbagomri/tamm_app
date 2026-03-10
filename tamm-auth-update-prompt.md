# PLANNING PROMPT — تحديث نظام المصادقة لتطبيق تمّ
# أرسل هذا النص كاملاً للنموذج المخطط

---

## دورك — مخطط فقط، لا تنفذ

أنت مهندس برمجيات خبير في Flutter و Supabase. دورك هنا هو **التخطيط والتحليل فقط** — لا تكتب كوداً تنفيذياً ولا تبدأ في البرمجة.

مهمتك الوحيدة: تحليل المتطلبات وإنشاء **خطة تنفيذ مفصّلة ومرتّبة** لتحديث نظام المصادقة في تطبيق Flutter اسمه **تمّ**، بحيث يستطيع نموذج منفذ آخر تنفيذ كل خطوة بدقة دون أي غموض أو تفكير معماري إضافي.

**الناتج المطلوب منك فقط:**
- قرارات معمارية موثّقة ومبرّرة
- ترتيب مرقّم وواضح للخطوات
- توصيف دقيق لكل ملف وكل دالة وكل جدول (بدون كتابة الكود الفعلي)
- نقاط تحقق بعد كل مرحلة

**لا تبدأ التنفيذ** — أنت المخطط فقط.

---

## الوضع الحالي (قبل التعديل)

النظام القديم كان يعمل هكذا:
- المستخدم يسجل بـ: الاسم + رقم الجوال + الإيميل + كلمة المرور
- تسجيل الدخول: إيميل + كلمة المرور
- جدول `profiles` موجود في Supabase مرتبط بـ `auth.users`

---

## المطلوب (بعد التعديل)

### نظام المصادقة الجديد
- **إلغاء كامل** لنظام الإيميل + كلمة المرور
- **الاستبدال بـ Google Sign-In فقط** كطريقة تسجيل دخول وحيدة
- الإيميل يُجلب تلقائياً من Google — لا يكتبه المستخدم

### شاشة إكمال البيانات (Onboarding)
تظهر **مرة واحدة فقط** بعد أول تسجيل دخول بـ Google، تطلب:
- الاسم الكامل (إلزامي)
- رقم الجوال (إلزامي) — بصيغة يمنية +967
- ~~المدينة~~ — **لا يوجد حقل مدينة** (سيُضاف لاحقاً GPS دقيق عبر خرائط قوقل عند الطلب)

### منطق التحقق من الدخول
```
المستخدم يضغط "ادخل بـ Google"
            ↓
Supabase يتحقق: هل هذا الإيميل موجود في profiles؟
            ↓
لا (أول مرة) ← شاشة Onboarding لإكمال البيانات
نعم + بيانات مكتملة ← الصفحة الرئيسية حسب الدور
نعم + بيانات ناقصة ← شاشة Onboarding مجدداً
```

---

## نظام الأدوار (Roles)

### الأدوار الثلاثة
```dart
enum UserRole { customer, technician, manager }
```

| الدور | كيف يُعيَّن | الواجهة |
|-------|------------|---------|
| `customer` | تلقائي عند أول تسجيل | واجهة العميل |
| `technician` | المدير يرقّيه | واجهة الفني |
| `manager` | مباشرة في قاعدة البيانات | لوحة التحكم |

### آلية الترقية من customer إلى technician
- المدير يبحث في لوحة التحكم **بالإيميل أو رقم الجوال**
- يجد المستخدم ← يضغط "ترقية إلى فني"
- يتغير `role` في جدول `profiles` من `customer` إلى `technician`
- في المرة القادمة يفتح التطبيق ← يرى واجهة الفني تلقائياً

---

## قاعدة البيانات — التعديلات المطلوبة

### جدول profiles الجديد (كامل)
```sql
create table public.profiles (
  id           uuid references auth.users(id) on delete cascade primary key,
  email        text unique not null,        -- من Google تلقائياً
  full_name    text,                        -- يكتبه المستخدم
  phone        text unique,                 -- يكتبه المستخدم +967XXXXXXXXX
  -- city: لا يوجد حقل مدينة — الموقع سيُجمع عبر GPS عند كل طلب
  role         text not null default 'customer'
                    check (role in ('customer','technician','manager')),
  is_complete  boolean not null default false, -- هل أكمل Onboarding؟
  avatar_url   text,                        -- من Google تلقائياً
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);
```

### RLS Policies المطلوبة
```sql
-- العميل يقرأ ويعدّل بياناته فقط
-- المدير يقرأ كل المستخدمين
-- المدير فقط يعدّل حقل role
-- لا أحد يحذف من هذا الجدول
```

### Trigger تلقائي
عند إنشاء مستخدم جديد في `auth.users` ينشئ تلقائياً سجلاً في `profiles` بـ:
- `id` من auth.users
- `email` من auth.users
- `avatar_url` من Google metadata
- `role = 'customer'`
- `is_complete = false`

---

## هيكل الملفات المتأثرة بالتعديل

```
lib/
├── core/
│   ├── router/
│   │   └── app_router.dart          ← تعديل Guards حسب is_complete و role
│   └── widgets/
│       └── google_sign_in_button.dart  ← widget جديد
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart    ← تعديل كامل
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── login_screen.dart   ← تعديل كامل
│   │   │   │   └── onboarding_screen.dart ← جديد
│   │   │   └── providers/
│   │   │       └── auth_provider.dart  ← تعديل
│   │   └── domain/
│   │       └── user_model.dart         ← تعديل
│   │
│   └── manager/
│       └── technicians/
│           └── screens/
│               └── promote_user_screen.dart ← جديد
```

---

## التفاصيل التقنية لكل ملف

### ١ — auth_repository.dart
يجب أن يحتوي على:
```dart
// الدوال المطلوبة:
Future<void> signInWithGoogle();
Future<void> signOut();
Future<bool> isProfileComplete(String userId);
Future<void> completeProfile({
  required String userId,
  required String fullName,
  required String phone,
  // لا يوجد حقل city — سيُضاف GPS لاحقاً
});
Stream<AuthState> get authStateChanges;
```

### ٢ — login_screen.dart
- خلفية داكنة بألوان تمّ
- شعار تمّ في المنتصف (خط Harmattan)
- نص "أهلاً بك في تمّ"
- نص فرعي "خدمات التكييف والطاقة الشمسية"
- زر Google Sign-In واضح واحترافي
- لا يوجد أي حقل نص أو كلمة مرور

### ٣ — onboarding_screen.dart
- يظهر مرة واحدة فقط
- لا يوجد زر رجوع (لا يستطيع تخطيها)
- حقل الاسم الكامل
- حقل رقم الجوال مع كود اليمن +967
- **لا يوجد حقل مدينة** — الموقع سيُجمع لاحقاً عبر GPS عند تقديم الطلب
- زر "ابدأ الآن" يحفظ البيانات ويوجه للصفحة الرئيسية

### ٤ — app_router.dart
منطق التوجيه الكامل:
```dart
// Guard المطلوب:
redirect: (context, state) {
  final isLoggedIn = /* تحقق من Supabase session */;
  final isComplete = /* تحقق من is_complete في profiles */;
  final role = /* role من profiles */;

  if (!isLoggedIn) return '/login';
  if (!isComplete) return '/onboarding';
  
  // توجيه حسب الدور
  if (role == 'manager') return '/manager/dashboard';
  if (role == 'technician') return '/technician/tasks';
  return '/customer/home';
}
```

### ٥ — promote_user_screen.dart (في لوحة المدير)
- حقل بحث يقبل إيميل أو رقم جوال
- يعرض بيانات المستخدم إذا وُجد
- زر "ترقية إلى فني" مع تأكيد
- رسالة "تمّ الترقية ✓" بعد النجاح

---

## إعداد Google Sign-In في Supabase

### الخطوات التي يجب توثيقها في الخطة:
1. تفعيل Google Provider في Supabase Dashboard
2. إنشاء OAuth credentials في Google Cloud Console
3. إضافة `client_id` في Supabase
4. إضافة Redirect URL في Google Console
5. إضافة الحزمة في pubspec.yaml:
   ```yaml
   google_sign_in: ^6.2.0
   ```
6. إعداد SHA-1 في Firebase/Google Console للأندرويد
7. إضافة URL Scheme في iOS Info.plist

---

## التقنيات والقيود الثابتة

- **Framework:** Flutter (Dart)
- **Backend:** Supabase
- **State Management:** Riverpod
- **Navigation:** GoRouter
- **الخط:** Harmattan من Google Fonts — إلزامي لكل النصوص
- **الألوان:** من AppColors فقط:
  ```dart
  bgPrimary   = Color(0xFF080E18)
  bgSurface   = Color(0xFF0D1825)
  bluePrimary = Color(0xFF1576D4)
  blueLight   = Color(0xFF3E9EF5)
  success     = Color(0xFF22C98A)  // لرسائل "تمّ ✓" فقط
  textPrimary = Color(0xFFE8F0F8)
  textSecond  = Color(0xFF7A96B0)
  ```
- **اتجاه النص:** RTL في كل مكان
- **اللغة:** كل نصوص الواجهة عربية

---

## ما تحتوي عليه الخطة المطلوبة

اكتب خطة تنفيذ تشمل:

1. **SQL كامل** لتعديل جدول profiles + Trigger + RLS Policies
2. **كود Dart كامل** لكل ملف متأثر بالتعديل
3. **خطوات إعداد Google Sign-In** في Supabase و Google Console
4. **ترتيب التنفيذ** خطوة بخطوة (ماذا أعدّل أولاً وماذا ثانياً)
5. **نقاط التحقق** بعد كل خطوة للتأكد أنها تعمل صح

---

## تعليمات الخطة

- اكتب الكود الكامل — لا تكتب "أضف كوداً هنا"
- كل ملف يبدأ بمساره الكامل: `// lib/features/auth/...`
- لا تختصر — النموذج المنفذ لن يفكر، فقط ينفذ
- رتّب الخطوات بحيث لا يوجد تعارض (قاعدة البيانات أولاً، ثم الكود)

---

## ابدأ الآن

حلّل المتطلبات وأنشئ الخطة كاملة — تذكّر: أنت مخطط فقط، لا تكتب كوداً تنفيذياً.
