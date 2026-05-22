# 📢 دليل المزامنة الشامل لمطور تطبيق فلاتر (Tamm Flutter Client Sync Guide)

مرحباً! لقد تم الانتهاء بنجاح من تطوير وتحديث مجموعة من الأنظمة الأساسية في لوحة تحكم الويب (`Next.js Web Admin / Client`)، وبما أن قاعدة البيانات مشتركة ومبنية بالكامل على **Supabase**، يجب مزامنة تطبيق الهاتف المحمول (تطبيق العميل والفني المكتوب بـ **Flutter**) ليعكس ويستفيد من هذه التحديثات.

يوضح هذا الدليل كافة التغيرات التي طرأت على الجداول، منطق العمل المضاف، والمهام والتعليمات البرمجية المطلوبة لتطبيق فلاتر.

---

## 1. التحديثات في بنية قاعدة البيانات (Supabase Shared Schema)

تم تحديث وتوسيع قاعدة البيانات بإضافة وتعديل الجداول التالية. يرجى مراجعة وتحديث كائنات النماذج (Models) في تطبيق فلاتر لتتوافق معها:

### أ. تحديثات جدول الطلبات `orders`
تمت إضافة الحقول التالية لدعم تفاصيل الدفع والموقع الجغرافي الدقيق:
- `contact_phone` (TEXT - nullable): رقم الهاتف الذي يدخله العميل أثناء الدفع (قد يختلف عن هاتف الحساب الشخصي).
- `payment_type` (TEXT - NOT NULL): طريقة الدفع المختارة من العميل ويأخذ القيم: `cash` (نقدي)، `bank` (تحويل بنكي)، `wallet` (محفظة إلكترونية).
- `payment_method_id` (UUID - nullable): يربط بجدول طرق الدفع (عند اختيار دفع بنكي أو محفظة).
- `city` (TEXT - nullable): مدينة العميل للتوصيل/الخدمة.
- `latitude` (NUMERIC - nullable): الإحداثي الجغرافي لخط العرض لموقع العميل.
- `longitude` (NUMERIC - nullable): الإحداثي الجغرافي لخط الطول لموقع العميل.
- `receipt_url` (TEXT - nullable): رابط صورة سند التحويل البنكي في حال اختار الدفع عبر التحويل البنكي وقام برفع السند.

### ب. جدول الفواتير الجديد `invoices`
يُستخدم لحفظ الفواتير القانونية الصادرة تلقائياً عند اكتمال الطلبات:
```sql
CREATE TABLE public.invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_number TEXT NOT NULL UNIQUE, -- ترقيم تسلسلي تلقائي يبدأ بـ (INV-YYYY-0001)
    order_id UUID NOT NULL UNIQUE REFERENCES public.orders(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    subtotal NUMERIC NOT NULL, -- مجموع أسعار المنتجات دون التركيب
    installation_fee NUMERIC NOT NULL DEFAULT 0, -- رسوم التركيب
    total_amount NUMERIC NOT NULL, -- المجموع الكلي للطلب المكتمل
    payment_type TEXT NOT NULL, -- طريقة الدفع (cash, bank, wallet)
    pdf_url TEXT, -- رابط معاينة الفاتورة التفاعلية
    issued_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```
*(ملاحظة: مفعلة عليه سياسة حماية RLS بحيث يمكن للعميل قراءة فواتيره الخاصة فقط).*

### ج. جدول حركات المخزون الجديد `stock_movements`
يتعقب عمليات خصم وإعادة تعبئة المنتجات:
```sql
CREATE TABLE public.stock_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    movement_type TEXT NOT NULL CHECK (movement_type IN ('import', 'sale', 'cancel_return', 'manual_adjustment')),
    quantity_before INT NOT NULL,
    quantity_after INT NOT NULL,
    quantity_change INT NOT NULL,
    notes TEXT,
    performed_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### د. نظام عمولة الفنيين الجديد (`commission_rules` & `technician_earnings`)
تم بناء نظام مخصص لحساب أرباح الفنيين تلقائياً بناءً على مهامهم:
* **جدول قواعد العمولات `commission_rules`**:
  - `id` (UUID - Primary Key)
  - `task_type` (TEXT): نوع المهمة ويأخذ القيم: `installation` (تركيب)، `maintenance` (صيانة)، `inspection` (كشف ومعاينة)، `quote_visit` (زيارة عرض سعر).
  - `commission_type` (TEXT): نوع الحساب ويأخذ: `percentage` (نسبة مئوية)، `fixed_amount` (مبلغ ثابت).
  - `value` (NUMERIC): القيمة (مثال: 50 لـ 50% أو 200 لـ 200 ريال).
  - `description` (TEXT): وصف باللغة العربية.
  - `is_active` (BOOLEAN)
* **جدول مستحقات الفنيين المكتسبة `technician_earnings`**:
  - `id` (UUID - Primary Key)
  - `technician_id` (UUID): يربط بجدول الفنيين `technicians(id)`.
  - `order_id` (UUID): يربط بجدول الطلبات `orders(id)`.
  - `task_type` (TEXT)
  - `order_amount` (NUMERIC): القيمة الكلية للطلب.
  - `commission_amount` (NUMERIC): العمولة الصافية للفني.
  - `is_paid` (BOOLEAN): هل تم تسليم المبلغ للفني أم لا.
  - `paid_at` (TIMESTAMPTZ)
  - `notes` (TEXT)

---

## 2. منطق الأعمال المحدث تلقائياً (Shared Backend Business Logic)

هناك منطق برمجيات يُنَفذ تلقائياً في السيرفر أو عبر التريجرات (Triggers) المشتركة ويجب الإحاطة به:

1. **الخصم والإرجاع التلقائي للمخزون (Inventory Auto-Management)**:
   - عند إنشاء طلب لمنتج، يتم تلقائياً خصم الكمية من `products.stock_quantity`.
   - إذا وصلت الكمية إلى `0` وكان الخيار `auto_hide_when_out` مفعلاً للمنتج، يتم تلقائياً ضبط `is_available = false` لإخفائه من المتجر.
   - **عند إلغاء الطلب (`status == 'cancelled'`)**، يتم إرجاع المنتجات تلقائياً للمخزن وتحديث الحقول تلقائياً.
2. **عند اكتمال الطلب (`status == 'completed'`)**:
   - يتم تلقائياً عبر السيرفر إصدار فاتورة في جدول `invoices` وحساب المجموع الكلي ورسوم التركيب بدقة.
   - يتم تلقائياً حساب عمولة الفني المكلف بالطلب بناءً على قواعد العمولة الفعالة، وتسجيلها في جدول `technician_earnings` كأرباح مستحقة له.
3. **تفعيل الإشعارات الفورية (Notifications & Realtime)**:
   - تم تفعيل ميزة البث الفوري (Realtime Replication) لجدولي `orders` و `notifications`؛ مما يتيح لتطبيق فلاتر الاستماع للتحديثات وعرض الإشعارات محلياً فور وقوعها.

---

## 3. المهام المطلوبة منك في تطبيق فلاتر (Flutter Mobile App)

يرجى توزيع وتطبيق المهام التالية على تطبيق العميل وتطبيق الفني:

### 📱 أولاً: تطبيق العميل (Customer App)

#### 1. شاشة الدفع والطلب (Checkout Screen):
- يرجى توفير واجهة لاختيار **طريقة الدفع (Payment Type)**:
  - نقدي (`cash`)
  - تحويل بنكي (`bank`): عند اختيار التحويل البنكي، اعرض للعميل الحسابات البنكية للمنصة (الموجودة في جدول `payment_methods` أو كحساب ثابت)، وأتح له **رفع صورة/ملف سند التحويل**.
  - بعد رفع السند إلى مستودع التخزين السحابي (Supabase Storage)، قم بحفظ الرابط في حقل `receipt_url` داخل الطلب.
- احرص على إرسال قيم الموقع الجغرافي `city` و `latitude` و `longitude` عند إنشاء الطلب لتمكين ميزة تعقب الفني في المستقبل وتسهيل مهمة التوصيل.

#### 2. شاشة تفاصيل الطلب وفاتورة الـ PDF التفاعلية:
عندما تكون حالة الطلب مكتملة (`status == 'completed'`)، نوفر لك خياراً ممتازاً وموصى به لعرض الفاتورة وتفادي مشاكل الخطوط العربية المتقطعة في فلاتر:
- أضف زراً مميزاً باسم `📄 عرض وتحميل الفاتورة`.
- عند الضغط عليه، استخدم حزمة `url_launcher` لفتح الرابط التفاعلي للفاتورة المصممة في بيئة الويب والمتوافقة تماماً مع الطباعة والتنزيل كـ PDF بخط **Tahoma** متصل ومثالي:
  `https://tamm-web.vercel.app/orders/[order_id]/invoice`
  *(استبدل `[order_id]` بمعرّف الطلب الفعلي UUID)*.
  
*مثال برمجى للفلاتر:*
```dart
import 'url_launcher/url_launcher.dart';

Future<void> openInvoicePdf(String orderId) async {
  final Uri url = Uri.parse('https://tamm-web.vercel.app/orders/$orderId/invoice');
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch invoice URL');
  }
}
```

#### 3. الاستماع للإشعارات المباشرة (Realtime Notifications):
استمع لجدول `notifications` المشترك باستخدام Supabase Realtime لإظهار تنبيهات للعميل عند تحديث حالة طلبه:
```dart
final subscription = supabase
    .from('notifications')
    .stream(primaryKey: ['id'])
    .eq('user_id', supabase.auth.currentUser!.id)
    .listen((List<Map<String, dynamic>> data) {
      // قم بالتحقق من الإشعارات الجديدة غير المقروءة وإظهار تنبيه محلي (Local Notification)
    });
```

---

### 🛠️ ثانياً: تطبيق الفني (Technician App)

بما أن تطبيق الفني مدمج ومبني بالكامل في فلاتر، يجب تعديل الشاشات والمنطق التالي:

#### 1. تحديث حالة العمل:
عندما يقوم الفني بالبدء في العمل أو إنجازه، فإنه يقوم بتحديث حالة الطلب (`status`) في جدول `orders`:
- عند تحركه: `status = 'on_the_way'`
- عند بدء العمل الفعلي: `status = 'in_progress'`
- **عند الانتهاء تماماً وتلقي الدفع**: `status = 'completed'`
  *(ملاحظة هامة: فور قيام الفني بتغيير الحالة إلى `completed` من الجوال، ستقوم قاعدة البيانات تلقائياً بتوليد الفاتورة للعميل وحساب عمولة هذا الفني وإضافتها لحسابه!)*.

#### 2. شاشة الأرباح المستحقة للفني (Technician Earnings Screen) - "جديدة":
يرجى بناء واجهة بسيطة في تطبيق الفني تعرض أرباحه وعمولاته المستحقة:
- قم بالاستعلام من جدول `technician_earnings` المصفى بمعرف الفني الحالي:
```dart
final earnings = await supabase
    .from('technician_earnings')
    .select('*, orders(order_number)')
    .eq('technician_id', currentTechnicianId)
    .order('created_at', ascending: false);
```
- اعرض أسطر الأرباح:
  - رقم الطلب (من العلاقة المدمجة)
  - نوع المهمة (تركيب، صيانة، كشف)
  - قيمة العمولة المستحقة بالريال السعودي.
  - حالة الدفع: (مستحقة / تم الاستلام) بناءً على قيمة الحقل `is_paid`.

---

## 4. نصائح برمجية هامة للربط (Best Practices)

- **التعامل مع الرموز الزمنية (Timestamps)**: تأكد من إرسال واستقبال التواريخ بصيغة UTC ISO 8601 (مثل `DateTime.now().toUtc().toIso8601String()`) لتجنب فروق التوقيت بين خوادم Supabase وهواتف المستخدمين.
- **التدفق المباشر للطلبات (Realtime Orders)**: للاستماع لأي تحديث في حالة الطلب بشكل لحظي في واجهة العميل أو الفني، استخدم الـ Streams المتاحة في حزمة Supabase الرسمية لفلاتر:
```dart
supabase
    .from('orders')
    .stream(primaryKey: ['id'])
    .eq('id', orderId)
    .listen((event) {
       // تحديث حالة الواجهة فوراً (مثال: شريط تتبع حالة الطلب)
    });
```

---
إذا كان لديك أي استفسار حول بنية البيانات أو كيفية ربط أي حقل محدد، فلا تتردد في طرحه! بالتوفيق! 🚀
