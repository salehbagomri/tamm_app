# ملخص تطبيق "تمّ" — Tamm App

> **هذا المستند موجّه لنموذج ذكاء اصطناعي للحصول على سياق كامل عن التطبيق قبل بدء أي نقاش تطويري.**

---

## 1. نظرة عامة

**تمّ (Tamm)** هو تطبيق متكامل لإدارة خدمات التكييف والطاقة الشمسية مبني بـ **Flutter**. يربط بين ثلاثة أطراف:
- **العميل (Customer):** يطلب المنتجات والخدمات ويتابع طلباته.
- **المدير (Manager):** يدير الطلبات والفنيين والمنتجات والخدمات والعروض.
- **الفني (Technician):** يستقبل مهامه المعينة ويتابع تنفيذها.

التطبيق منشور على:
- **Android** (APK / Play Store)
- **الويب**: https://tamm-app-8c990.web.app (Firebase Hosting)

---

## 2. التقنيات والبنية التحتية

| الطبقة | التقنية |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Riverpod (`flutter_riverpod`) |
| Backend / قاعدة البيانات | Supabase (PostgreSQL + Auth + Storage + Edge Functions) |
| التوجيه (Routing) | go_router |
| المصادقة | Google Sign-In (موبايل: ID Token، ويب: OAuth Redirect عبر Supabase) |
| الإشعارات | Firebase Cloud Messaging (FCM) — موبايل فقط |
| رفع الملفات | Supabase Storage (صور المنتجات، مرفقات عروض الأسعار) |
| التخزين المؤقت للصور | cached_network_image |
| الخطوط | Google Fonts (Harmattan للعربية) |
| التاريخ والوقت | intl (مع دعم العربية `ar`) |
| Hosting | Firebase Hosting (SPA rewrite rules) |

---

## 3. هيكل المشروع

```
lib/
├── main.dart                    # نقطة الدخول الرئيسية
├── app.dart                     # إعداد MaterialApp + go_router
├── core/
│   ├── config/env.dart          # Supabase URL + Anon Key (من .env)
│   ├── constants/               # app_colors, app_spacing, app_strings
│   ├── router/app_router.dart   # تعريف جميع مسارات التطبيق
│   ├── services/fcm_service.dart # إشعارات FCM (تعمل فقط على الموبايل)
│   ├── utils/
│   │   ├── platform_utils.dart  # فحص المنصة (كIsWeb-safe)
│   │   └── responsive.dart      # Breakpoints: Mobile/Tablet/Desktop
│   └── widgets/
│       ├── responsive_wrapper.dart  # يحصر المحتوى بعرض مناسب للشاشة
│       ├── adaptive_shell.dart      # يختار بين BottomNav وSidebar تلقائياً
│       ├── tamm_button.dart
│       ├── tamm_card.dart
│       ├── tamm_shimmer.dart
│       └── tamm_empty_state.dart
├── features/
│   ├── auth/                    # شاشة تسجيل الدخول + Onboarding
│   ├── customer/
│   │   ├── customer_shell.dart  # Navigation Shell للعميل
│   │   ├── home/                # الصفحة الرئيسية للعميل
│   │   ├── store/               # المتجر + فلترة المنتجات + سلة التسوق
│   │   ├── services/            # قائمة الخدمات + تفاصيل الخدمة
│   │   ├── search/              # البحث عن المنتجات
│   │   └── profile/             # حساب العميل + طلباته + أجهزته
│   ├── manager/
│   │   ├── manager_shell.dart   # Navigation Shell للمدير
│   │   ├── dashboard/           # لوحة التحكم + إحصائيات الطلبات
│   │   ├── orders/              # إدارة جميع الطلبات
│   │   ├── quotes/              # إدارة عروض الأسعار
│   │   ├── products/            # إدارة المنتجات (CRUD)
│   │   ├── services/            # إدارة الخدمات (CRUD)
│   │   ├── technicians/         # إدارة الفنيين
│   │   └── promotions/          # إدارة العروض والتخفيضات
│   ├── technician/
│   │   ├── technician_shell.dart
│   │   ├── tasks/               # قائمة مهام الفني + التفاصيل
│   │   └── profile/             # ملف الفني الشخصي
│   └── profile/
│       └── screens/edit_profile_screen.dart
└── shared/
    ├── models/
    │   ├── user_profile.dart    # id, email, fullName, phone, role, avatarUrl
    │   ├── product.dart         # id, name, category, price, oldPrice, specs, requiresInstallation
    │   ├── order.dart           # id, orderType, status, items, quoteStatus, quotePrice, ...
    │   ├── service_type.dart    # id, name, category, basePrice, isQuoteBased
    │   ├── promotion.dart       # عروض وتخفيضات
    │   └── cart_item.dart       # منتج + includeInstallation
    ├── providers/               # جميع Riverpod providers
    └── repositories/
        ├── auth_repository.dart
        ├── cart_repository.dart
        └── quote_repository.dart
```

---

## 4. أدوار المستخدمين والصلاحيات

### العميل (role: `customer`)
- تسجيل الدخول عبر Google.
- إكمال بيانات البروفايل (Onboarding) عند أول دخول.
- تصفح المتجر وفلترة المنتجات (حسب الفئة، السعر، العروض).
- إضافة منتجات للسلة مع خيار "تضمين التركيب".
- إتمام الطلبات (منتج، خدمة، أو طلب عرض سعر).
- متابعة حالة الطلبات الحالية والسابقة.
- قبول أو رفض عروض الأسعار المرسلة من المدير.
- إدارة أجهزته المسجلة (الأجهزة المنزلية).
- تعديل بيانات الحساب أو حذفه.

### المدير (role: `manager`)
- عرض إحصائيات لوحة التحكم (معلق، جاري، مكتمل، عروض تحتاج إجراء).
- مراجعة الطلبات وتعيين فني لكل طلب.
- جدولة الطلبات (يوم + وقت).
- رفع وتعديل عروض الأسعار مع المرفقات (PDF, صور).
- إدارة المنتجات كاملاً (CRUD + صور).
- إدارة الخدمات (CRUD).
- إدارة الفنيين (إضافة / حذف).
- إدارة العروض والتخفيضات (Promotions).
- استقبال تحديثات الطلبات لحظياً عبر Supabase Realtime.

### الفني (role: `technician`)
- استعراض قائمة المهام المعينة له.
- تحديث حالة كل مهمة (في الطريق، جاري التنفيذ، مكتمل).
- إضافة ملاحظات فنية على كل مهمة.

---

## 5. نماذج البيانات الرئيسية (Data Models)

### UserProfile
```
id, email, fullName, phone, role (customer|manager|technician),
isComplete, avatarUrl, address, createdAt
```

### Product
```
id, name, description, category (ac|solar_panel|solar_battery|solar_inverter|accessory),
price, oldPrice, isPriceOnRequest, imageUrl, brand,
specs (Map), isAvailable, isFeatured, requiresInstallation, installationPrice
```

### Order
```
id, orderNumber, customerId, orderType (product|service|product_and_service|quote_request),
status (pending|confirmed|assigned|on_the_way|in_progress|completed|cancelled),
totalAmount, address, preferredDate, preferredTimeSlot, notes, includeInstallation,
items (List<OrderItem>), technicianName, technicianNotes,
scheduledPeriod, scheduledHour,
quotePrice, quoteDetails, quoteDuration,
quoteStatus (pending|sent|accepted|rejected), quoteSentAt, quoteRespondedAt,
rejectionReason, quoteAttachmentUrl
```

### ServiceType
```
id, name, description, category (ac_install|ac_repair|ac_wash|ac_maintenance|
solar_install|solar_maintenance|consultation),
basePrice, iconName, isActive, isQuoteBased, includes (List<String>), estimatedDuration
```

### OrderItem
```
id, orderId, itemType (product|service), productId, serviceTypeId,
quantity, unitPrice, totalPrice
```

---

## 6. تدفق المصادقة (Auth Flow)

```
[شاشة تسجيل الدخول]
    │
    ├─ (موبايل) Google Sign-In SDK → ID Token → Supabase signInWithIdToken
    └─ (ويب)    Supabase signInWithOAuth(Google) → OAuth Redirect → tamm-app-8c990.web.app
                                                                      │
                                                              Supabase يحفظ الجلسة
                                                                      │
                                                    [فحص isProfileComplete]
                                                      │                │
                                                  ناقص               مكتمل
                                                      │                │
                                           [Onboarding Screen]  [توجيه حسب الدور]
                                                                 customer / manager / technician
```

---

## 7. تدفق الطلبات (Order Flow)

### طلب منتج عادي:
```
العميل يضيف للسلة → يتمّ الطلب → status: pending
→ المدير يراجع ويعيّن فني → status: assigned
→ الفني يتحرك → status: on_the_way
→ الفني يبدأ → status: in_progress
→ الفني ينهي → status: completed
```

### طلب عرض سعر (Quote Request):
```
العميل يطلب عرض سعر → orderType: quote_request, quoteStatus: pending
→ المدير يرفع عرض السعر (سعر + تفاصيل + مرفق اختياري) → quoteStatus: sent
→ العميل يقبل → quoteStatus: accepted → المدير يعيّن فني ويكمل كطلب عادي
→ العميل يرفض → quoteStatus: rejected → يمكن للمدير رفع عرض جديد
```

---

## 8. التصميم المتجاوب (Responsive Design)

| حجم الشاشة | السلوك |
|---|---|
| موبايل (< 768px) | BottomNavigationBar، شبكة 2 أعمدة |
| تابلت (768–1199px) | NavigationRail (sidebar)، شبكة 3–4 أعمدة |
| ديسكتوب (≥ 1200px) | NavigationRail موسّع + عناوين، شبكة 4–5 أعمدة |

الشاشات المطبّق عليها `ResponsiveWrapper`:
- الصفحة الرئيسية للعميل
- المتجر
- الخدمات
- حساب العميل
- لوحة تحكم المدير

---

## 9. قاعدة البيانات (Supabase)

**الجداول الرئيسية:**
- `profiles` — بيانات المستخدمين (مرتبط بـ auth.users)
- `products` — المنتجات
- `service_types` — أنواع الخدمات
- `orders` — الطلبات
- `order_items` — عناصر كل طلب
- `assignments` — تعيين فني لطلب
- `technicians` — بيانات إضافية للفنيين
- `promotions` — العروض والتخفيضات
- `user_devices` — أجهزة العميل المسجلة
- `fcm_tokens` — tokens الإشعارات

**Edge Functions:**
- `delete-user` — حذف الحساب نهائياً من Supabase Auth

**Realtime:**
- المدير يستقبل تحديثات الطلبات لحظياً عبر Supabase Realtime Channels

---

## 10. الإشعارات (FCM)

- تعمل فقط على الموبايل (`kIsWeb == false`).
- عند تسجيل الدخول، يتم رفع FCM Token إلى جدول `fcm_tokens`.
- عند تسجيل الخروج، يتم حذف الـ Token.
- مهيأ عبر `firebase_messaging` مع `firebase_options.dart`.

---

## 11. التطوير الحالي والمخطط

### ما تم إنجازه ✅:
- بناء التطبيق كاملاً (موبايل + ويب).
- نظام المصادقة (Google Sign-In) لكلا المنصتين.
- إدارة الطلبات بجميع أنواعها.
- نظام عروض الأسعار مع المرفقات.
- التصميم المتجاوب (Adaptive Sidebar + Responsive Grid).
- النشر على Firebase Hosting.
- إعداد Google OAuth Consent Screen (In Production).
- إعداد Supabase Redirect URLs.

### ما يمكن تطويره 🔧:
- تحسين تجربة المستخدم في الشاشات التفصيلية (تفاصيل المنتج، الطلب، الخدمة).
- إضافة نظام تقييم الطلبات المكتملة.
- لوحة إحصائيات أكثر تفصيلاً للمدير (رسوم بيانية).
- إضافة دعم الدفع الإلكتروني.
- تحسين شاشة تتبع الطلب لحظياً للعميل.
- إضافة نظام الإشعارات للويب (Web Push).
- تحسين أداء شاشة المتجر (Pagination / Infinite Scroll).
- نظام الكوبونات للعروض.
- دعم تعدد اللغات (عربي / إنجليزي).

---

## 12. بيانات تقنية للمرجعية

- **Firebase Project ID:** `tamm-app-8c990`
- **Web App URL:** https://tamm-app-8c990.web.app
- **GitHub Repo:** https://github.com/salehbagomri/tamm_app
- **Branch الرئيسي:** `main`
- **Flutter SDK:** أحدث نسخة stable
- **Dart:** null-safe
- **Target platforms:** Android, Web
- **اللغة الأساسية للواجهة:** العربية (RTL)
- **الخط الرئيسي:** Harmattan (Google Fonts)
- **نظام الألوان:** Dark Mode بالكامل (AppColors - درجات الأزرق الداكن)
