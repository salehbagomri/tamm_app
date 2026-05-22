# 🛒 دليل مزامنة المرحلة الأولى لمطور فلاتر: إدارة المخزون وفحوصات الكميات الصارمة

مرحباً! يركز هذا الدليل على **المرحلة الأولى (Phase 1: Inventory & Stock Management)** التي تم بناؤها في المتجر الإلكتروني لمنصة تمّ. 

يتطلب هذا التطوير مزامنة دقيقة في تطبيق الجوال (Flutter) لضمان عدم بيع أي منتجات بنفاد مخزونها، وعرض تنبيهات واضحة للمستخدمين، وإجراء عمليات التحقق في أربع نقاط حاسمة.

---

## 1. التحديثات في جدول المنتجات `products` والنموذج (Model)

تم إدخال حقول جديدة للمنتجات في قاعدة البيانات. يرجى تحديث نموذج `Product` في الفلاتر ليحتوي على هذه الحقول:

```dart
class Product {
  final String id;
  final String name;
  final String? description;
  final String category; // 'ac', 'solar_panel', 'solar_battery', 'solar_inverter', 'accessory'
  final double? price;
  final double? oldPrice;
  final bool isPriceOnRequest;
  final String? imageUrl;
  final String? brand;
  final Map<String, dynamic> specs;
  final bool isAvailable;
  final bool isFeatured;
  final bool requiresInstallation;
  final double installationPrice;
  
  // ─── حقول المخزون والتكلفة الجديدة (Phase 1) ───
  final double? costPrice;        // سعر التكلفة (سرّي - للمدير فقط)
  final int stockQuantity;        // الكمية المتوفرة بالمخزن
  final int lowStockThreshold;    // حد المخزون المنخفض (افتراضي 3)
  final String? supplierName;     // اسم المورد
  final String? supplierSku;      // كود المورد
  final bool autoHideWhenOut;     // الإخفاء التلقائي للمنتج عند نفاد الكمية (افتراضي true)

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.price,
    this.oldPrice,
    required this.isPriceOnRequest,
    this.imageUrl,
    this.brand,
    required this.specs,
    required this.isAvailable,
    required this.isFeatured,
    required this.requiresInstallation,
    required this.installationPrice,
    this.costPrice,
    required this.stockQuantity,
    required this.lowStockThreshold,
    this.supplierName,
    this.supplierSku,
    required this.autoHideWhenOut,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      oldPrice: json['old_price'] != null ? (json['old_price'] as num).toDouble() : null,
      isPriceOnRequest: json['is_price_on_request'] ?? false,
      imageUrl: json['image_url'],
      brand: json['brand'],
      specs: json['specs'] ?? {},
      isAvailable: json['is_available'] ?? true,
      isFeatured: json['is_featured'] ?? false,
      requiresInstallation: json['requires_installation'] ?? false,
      installationPrice: json['installation_price'] != null ? (json['installation_price'] as num).toDouble() : 0.0,
      costPrice: json['cost_price'] != null ? (json['cost_price'] as num).toDouble() : null,
      stockQuantity: json['stock_quantity'] ?? 0,
      lowStockThreshold: json['low_stock_threshold'] ?? 3,
      supplierName: json['supplier_name'],
      supplierSku: json['supplier_sku'],
      autoHideWhenOut: json['auto_hide_when_out'] ?? true,
    );
  }
}
```

---

## 2. الدورة التشغيلية للمخزون ونقاط المزامنة الأربعة في تطبيق Flutter

لتحقيق متانة تشغيلية وتجربة مستخدم خالية من العيوب، يجب تطبيق الفحوصات والخصومات في 4 نقاط رئيسية داخل تطبيق فلاتر:

```
[1. صفحة تفاصيل المنتج]
      ↓ التحقق عند الإضافة للسلة لمنع طلب كميات مفرطة
[2. صفحة السلة]
      ↓ التحقق الديناميكي أثناء التعديل
[3. شاشة تأكيد الشراء (Checkout)]
      ↓ استعلام أخير مباشر من قاعدة البيانات قبل إطلاق الطلب + الخصم الفعلي
[4. عند إلغاء الطلب]
      ↓ إعادة الكميات المخصومة تلقائياً للمخزن
```

---

### 1️⃣ التحقق الفوري عند الإضافة للسلة (Add to Cart Verification)
عندما يضغط العميل على زر **"إضافة للسلة"** في صفحة تفاصيل المنتج أو قائمة المتجر:
- يجب التأكد من أن الكمية الإجمالية التي سيطلبها العميل (الكمية بالسلة حالياً + الكمية المراد إضافتها) **لا تتجاوز** كمية المخزون الفعلي (`stockQuantity`).
- إذا كانت الكمية المتوفرة `0` أو المنتج غير متوفر، يتم تعطيل الزر وكتابة: **"نفد من المخزن 🔴"**.
- إذا كانت الكمية المطلوبة أكبر من المتوفر، اعرض رسالة خطأ واضحة باللغة العربية.

*مثال برمجى للفلاتر عند النقر:*
```dart
void handleAddToCart(BuildContext context, Product product, int requestedQty) {
  // جلب كمية هذا المنتج الموجودة في السلة حالياً
  final int qtyInCart = cartProvider.getItemQuantity(product.id);
  final int totalRequested = qtyInCart + requestedQty;

  if (product.stockQuantity <= 0 || !product.isAvailable) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('عذراً، هذا المنتج غير متوفر حالياً في المخزن.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (totalRequested > product.stockQuantity) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'عذراً، لا يمكنك إضافة هذه الكمية. المتوفر في المخزن هو ${product.stockQuantity} قطعة فقط، ولديك $qtyInCart قطعة في السلة.',
        ),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  // إضافة المنتج بنجاح
  cartProvider.addToCart(product, requestedQty);
}
```

---

### 2️⃣ صفحة السلة (Cart Screen)
أثناء قيام العميل بزيادة الكمية داخل صفحة السلة باستخدام أزرار `(+)` و `(-)`:
- يرجى تقييد الزر `(+)` بحيث لا يستطيع العميل تجاوز حقل `product.stockQuantity`.
- في حال وصول كمية السلة للحد الأقصى للمخزون، عطل الزر `(+)` أو اعرض تنبيهاً خفيفاً: `وصلت للحد الأقصى للمخزون`.

---

### 3️⃣ فحص اللحظة الأخيرة قبل الشراء وتأكيد الدفع (Pre-Checkout & Checkout Check)
قبل إرسال الطلب وحفظه في جدول `orders` مباشرة (Race Condition Prevention):
1. **استعلام مباشر وسريع**: قم بجلب أحدث كميات الأصناف الموجودة بالسلة من قاعدة بيانات Supabase.
2. **مطابقة المخزون الفعلي**: تأكد أن الكميات لم تنفد أثناء تصفح العميل للمتجر.
3. **الخصم الفعلي للمخزون**: عند نجاح الفحص، قم بخصم الكمية، وتحديث حالة التوفر (`is_available = false` إذا كانت الكمية الجديدة `<= 0` وكان خيار `auto_hide_when_out` مفعلاً)، وسجل حركة المخزون في جدول `stock_movements`.

*مثال الكود الكامل لإتمام الفحص والخصم السحابي:*
```dart
Future<Map<String, dynamic>> processCheckout(List<CartItem> cartItems, String userId) async {
  final supabase = Supabase.instance.client;

  try {
    // 1. استعلام عن المخزون الحالي للأصناف المطلوبة
    final List<String> productIds = cartItems.map((item) => item.productId).toList();
    
    final response = await supabase
        .from('products')
        .select('id, name, stock_quantity, auto_hide_when_out, is_available')
        .in_('id', productIds);

    final List<dynamic> dbProducts = response as List<dynamic>;

    // 2. الفحص والمطابقة الصارمة
    for (var item in cartItems) {
      final dbProd = dbProducts.firstWhere((p) => p['id'] == item.productId, orElse: () => null);
      if (dbProd == null) {
        return {'success': false, 'message': 'المنتج "${item.name}" لم يعد متوفراً في النظام.'};
      }

      final int currentStock = dbProd['stock_quantity'] ?? 0;
      if (currentStock < item.quantity) {
        return {
          'success': false,
          'message': 'عذراً، الكمية المطلوبة من "${item.name}" غير متوفرة. المتوفر حالياً: $currentStock قطعة فقط.'
        };
      }
    }

    // 3. الخصم وتحديث الجداول (يرجى تنفيذها في عملية واحدة أو باستخدام RPC إن أمكن)
    for (var item in cartItems) {
      final dbProd = dbProducts.firstWhere((p) => p['id'] == item.productId);
      final int currentStock = dbProd['stock_quantity'] ?? 0;
      final int newStock = currentStock - item.quantity;
      final bool autoHide = dbProd['auto_hide_when_out'] ?? true;

      Map<String, dynamic> updateFields = {
        'stock_quantity': newStock,
      };

      // إذا وصلت الكمية لـ 0 والإخفاء التلقائي مفعل، قم بإخفاء المنتج
      if (newStock <= 0 && autoHide) {
        updateFields['is_available'] = false;
      }

      // تحديث مخزون المنتج
      await supabase.from('products').update(updateFields).eq('id', item.productId);

      // تسجيل حركة المخزون في جدول stock_movements
      await supabase.from('stock_movements').insert({
        'product_id': item.productId,
        'movement_type': 'sale',
        'quantity_before': currentStock,
        'quantity_after': newStock,
        'quantity_change': -item.quantity,
        'notes': 'مبيعات من تطبيق الجوال للطلب المباشر',
        'performed_by': userId,
      });
    }

    return {'success': true};
  } catch (e) {
    return {'success': false, 'message': 'فشل الاتصال بقاعدة البيانات للتحقق من المخزون: $e'};
  }
}
```

---

### 4️⃣ عند إلغاء الطلب (Order Cancellation Restoration)
في حال قام العميل أو المدير بإلغاء الطلب (`status == 'cancelled'`)، يجب **إرجاع الكميات المبيوعة** إلى مخزون المنتجات تلقائياً:
- قم بقراءة عناصر الطلب الملغى من جدول `order_items`.
- قم بزيادة `stock_quantity = stock_quantity + item.quantity` لكل منتج.
- **تنشيط التوافر مجدداً**: إذا كانت الكمية السابقة `0` والمنتج كان مخفياً (`is_available = false` و `auto_hide_when_out = true`)، قم بضبط `is_available = true` تلقائياً فوراً بمجرد عودة المخزون لأكبر من الصفر.
- سجل حركة مخزون جديدة من نوع `cancel_return` في جدول `stock_movements`.

---

## 3. تحسينات الهوية البصرية وتجربة المستخدم (UI/UX)

- **مؤشر المخزون المنخفض (Low Stock Indicator)**:
  إذا كان المنتج متوفراً ولكن كميته مساوية أو أقل من `lowStockThreshold` (افتراضياً 3 قطع)، اعرض بطاقة أو نصاً تنبيهياً بلون برتقالي/أصفر في تفاصيل المنتج: 
  `⚠️ متبقي عدد محدود جداً في المخزن ([stockQuantity] قطع)!`
- **التصميم في حال نفاد الكمية**:
  إذا نفدت كمية المنتج بالكامل:
  - عطل زر الإضافة للسلة تماماً واجعله بلون رمادي خافت.
  - اعرض ملصق واضح: `غير متوفر / نفدت الكمية`.

تطبيق هذه الفحوصات في واجهات فلاتر سيمنع تماماً أي مبيعات خاطئة أو مشاكل تشغيلية مع الموردين! بالتوفيق! 🚀
