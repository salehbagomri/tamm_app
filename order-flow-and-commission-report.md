# تقرير تفصيلي: معالجة طلبات التوصيل فقط، منطق العمولات، وتريجر إتمام الطلب (Supabase Webhook)

يحتوي هذا التقرير على توثيق كامل وشامل لكيفية معالجة طلبات المنتجات بدون تركيب (Delivery-only) وآلية حساب العمولات الخاصة بالفنيين، بالإضافة إلى التريجر وقناة الويب هوك (Webhook) المشتركة في Supabase. تم إعداد هذا التقرير لتقديمه للوكيل الذكي (Agent) المسؤول عن تطبيق فلاتر (Flutter App) لضمان اتساق منطق الأعمال والتعامل مع قاعدة البيانات المشتركة.

---

## 1. تدفق طلبات التوصيل فقط (Delivery-Only Orders)

### آلية التعرف على الطلب:
في لوحة تحكم المدير، يتم تصنيف الطلب كـ "توصيل فقط" (لا يتطلب فني تركيب) بناءً على الشرط التالي:
* أن يكون نوع الطلب منتجاً (`orderType === 'product'`).
* أن تكون جميع العناصر المشتراة لا تتضمن تركيباً (`includeInstallation === false`).

### سلوك واجهة المستخدم (UI Logic):
* **حظر تعيين الفنيين:** يتم إخفاء خيار تعيين الفني وجدولة الموعد تماماً لمنع إسناد مهمة التركيب إلى أي فني.
* **إدارة حالة الطلب:** يتم عرض أزرار مخصصة وسريعة تتيح للمسؤول ترقية حالة الطلب يدوياً عبر الخطوات التالية:
  1. من معلق (`pending`) إلى مؤكد (`confirmed`) عبر زر **✓ تأكيد الطلب**.
  2. من مؤكد (`confirmed`) إلى في الطريق (`on_the_way`) عبر زر **🚚 بدء التوصيل**.
  3. من في الطريق (`on_the_way`) إلى مكتمل (`completed`) عبر زر **📬 تم التسليم**.

### آلية حساب العمولة لطلب التوصيل فقط:
عند إتمام الطلب وانتقاله إلى حالة `completed`، تفشل عملية تسجيل العمولة تلقائياً وتسجل الخطأ التالي في الخادم لعدم وجود فني مسند في جدول التعيينات (`assignments`):
`[Commission] لا يوجد فني معين للطلب`
وهذا هو السلوك الصحيح حيث لا يتم صرف أي عمولة فنية لعمليات التوصيل البسيطة.

---

## 2. منطق حساب العمولات (Commission Calculation Logic)

يتم تخزين قواعد العمولات في جدول `commission_rules` وتُحسب العمولة تلقائياً عند إتمام الطلب كالتالي:

### تصنيف المهمة (Task Type):
* **التركيب (`installation`):** للطلبات من نوع منتج (`product`) وتحتوي على تركيب.
* **الصيانة (`maintenance`):** لطلبات الخدمات (`service`) أو طلبات المنتجات بدون تركيب (إذا تم تعيين فني لها بطرق أخرى).

### طريقة الحساب:
1. **عمولة بمبلغ ثابت (`fixed_amount`):** يحصل الفني على القيمة المحددة في القاعدة مباشرة (مثال: 50 ريال).
2. **عمولة بنسبة مئوية (`percentage`):**
   * **في طلبات التركيب (`installation`):** تُحسب النسبة المئوية **من قيمة التركيب فقط**، وتُستثنى قيمة المنتج الأساسي.
     * معادلة احتساب قيمة التركيب لمنتج: `قيمة التركيب = السعر الإجمالي للعنصر - (سعر الوحدة الأساسي × الكمية)`.
     * العمولة: `(قيمة التركيب × النسبة المئوية) / 100`.
   * **في طلبات الصيانة (`maintenance`):** تُحسب النسبة المئوية من **إجمالي قيمة الطلب بالكامل**:
     * العمولة: `(إجمالي قيمة الطلب × النسبة المئوية) / 100`.

---

## 3. تريجر إتمام الطلب والويب هوك (Supabase Webhook Trigger)

يتشارك تطبيق الويب وتطبيق الهاتف نفس قاعدة البيانات ونفس تريجر إتمام الطلب:

* **التريجر في قاعدة البيانات:** يدعى `on_order_completed` على جدول `orders`.
* **الوظيفة:** عند تحديث حالة الطلب إلى `completed`، يطلق التريجر وظيفة `public.handle_order_completed()` والتي ترسل طلب HTTP POST (Webhook) غير متزامن إلى الخادم:
  `http://localhost:3000/api/webhooks/order-completed`
* **السرية والأمان:** يمرر التريجر رأس المصادقة `x-webhook-secret` بقيمة `tamm_webhook_secret_2026_secure` للتأكد من موثوقية الطلب، وهو ما يطابق المتغير البيئي `SUPABASE_WEBHOOK_SECRET` في ملف `.env.local` للخادم.
* **المعالجة المزدوجة:** لحماية النظام من حساب العمولة مرتين (تكرار الاستدعاء من الويب هوك والتحديث اليدوي)، تتحقق دالة الحساب دائماً من عدم وجود عمولة سابقة في جدول `technician_earnings` لنفس معرف الطلب قبل إجراء عملية الإدراج.

---

## 4. الرموز المصدرية الكاملة (Source Code Reference)

### أ. كود حساب العمولة وتفاصيل المنطق
**الملف:** `lib/actions/admin/commissions.ts`
```typescript
'use server'

import { revalidatePath } from 'next/cache'
import { createServerClient, createAdminClient } from '@/lib/supabase/server'
import type { TaskType, CommissionType } from '@/lib/types/commission'

// ─── حساب العمولة تلقائياً عند إتمام طلب ──────────────────────────────────────

export async function calculateCommissionForOrder(orderId: string): Promise<{ error?: string }> {
  try {
    // نستخدم Admin Client لتجاوز قيود RLS
    const supabase = createAdminClient()

    console.log('[Commission] بدء حساب العمولة للطلب:', orderId)

    // جلب بيانات الطلب
    const { data: order, error: orderErr } = await supabase
      .from('orders')
      .select(`
        id, order_type, total_amount, include_installation,
        order_items(item_type, unit_price, total_price, quantity, include_installation)
      `)
      .eq('id', orderId)
      .single()

    if (orderErr || !order) {
      console.error('[Commission] فشل جلب الطلب:', orderErr)
      return { error: 'الطلب غير موجود' }
    }

    console.log('[Commission] نوع الطلب:', order.order_type, '| المبلغ:', order.total_amount)

    // جلب الفني من جدول التعيينات
    const { data: assignment } = await supabase
      .from('assignments')
      .select('technician_id')
      .eq('order_id', orderId)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    // fallback: إذا لم يوجد في assignments، نبحث في technician_id بالطلب مباشرة
    let technicianId = assignment?.technician_id ?? null

    if (!technicianId) {
      const { data: orderDirect } = await supabase
        .from('orders')
        .select('technician_id')
        .eq('id', orderId)
        .single()
      technicianId = orderDirect?.technician_id ?? null
    }

    if (!technicianId) {
      console.error('[Commission] لا يوجد فني معين للطلب:', orderId)
      return { error: 'لا يوجد فني معين لهذا الطلب' }
    }

    console.log('[Commission] الفني المعين:', technicianId)

    // التحقق من عدم وجود عمولة مسجلة مسبقاً لمنع التكرار
    const { data: existing } = await supabase
      .from('technician_earnings')
      .select('id')
      .eq('order_id', orderId)
      .maybeSingle()

    if (existing) {
      console.log('[Commission] العمولة مسجلة مسبقاً — تم التخطي')
      return {}
    }

    // تحديد نوع المهمة بناءً على نوع الطلب
    let taskType: TaskType = 'maintenance'
    const items = order.order_items as Array<{
      item_type: string
      unit_price: number
      total_price: number
      quantity: number
      include_installation: boolean
    }> | null

    if (order.order_type === 'product') {
      const hasInstallation = items?.some(i => i.include_installation) || order.include_installation
      taskType = hasInstallation ? 'installation' : 'maintenance'
    } else if (order.order_type === 'service') {
      taskType = 'maintenance'
    } else if (order.order_type === 'quote') {
      taskType = 'quote_visit'
    } else if (order.order_type === 'inspection') {
      taskType = 'inspection'
    }

    console.log('[Commission] نوع المهمة:', taskType)

    // جلب قاعدة العمولة المناسبة والمفعّلة من جدول القواعد
    const { data: rule, error: ruleErr } = await supabase
      .from('commission_rules')
      .select('*')
      .eq('task_type', taskType)
      .eq('is_active', true)
      .limit(1)
      .maybeSingle()

    if (ruleErr || !rule) {
      console.error('[Commission] لم يتم العثور على قاعدة عمولة للنوع:', taskType, ruleErr)
      return { error: 'لا توجد قاعدة عمولة مفعّلة لهذا النوع من المهام' }
    }

    console.log('[Commission] القاعدة:', rule.commission_type, '=', rule.value)

    // حساب مبلغ العمولة
    let commissionAmount = 0
    const orderAmount = Number(order.total_amount)

    if (rule.commission_type === 'fixed_amount') {
      commissionAmount = Number(rule.value)
    } else {
      // احتساب النسبة المئوية
      if (taskType === 'installation') {
        let installationFee = 0
        if (items) {
          for (const item of items) {
            const baseTotal = item.unit_price * item.quantity
            const installPart = Math.max(0, item.total_price - baseTotal)
            installationFee += installPart
          }
        }
        // العمولة هي النسبة المئوية من رسوم التركيب فقط
        commissionAmount = (installationFee * Number(rule.value)) / 100
      } else {
        // العمولة هي النسبة المئوية من إجمالي قيمة الطلب بالكامل
        commissionAmount = (orderAmount * Number(rule.value)) / 100
      }
    }

    console.log('[Commission] مبلغ العمولة المحسوب:', commissionAmount)

    // تسجيل العمولة في جدول أرباح الفنيين
    const { error: insertError } = await supabase
      .from('technician_earnings')
      .insert({
        technician_id: technicianId,
        order_id: orderId,
        task_type: taskType,
        order_amount: orderAmount,
        commission_amount: commissionAmount,
      })

    if (insertError) {
      console.error('[Commission] فشل الإدراج:', insertError)
      return { error: `فشل تسجيل العمولة: ${insertError.message}` }
    }

    console.log('[Commission] ✅ تم تسجيل العمولة بنجاح!')
    revalidatePath('/admin/technicians')
    revalidatePath('/admin/technicians/earnings')
    return {}
  } catch (err) {
    console.error('[Commission] خطأ غير متوقع:', err)
    return { error: 'حدث خطأ أثناء حساب العمولة' }
  }
}
```

### ب. كود ملف الـ Migration لتريجر قاعدة البيانات
**الملف:** `supabase/migrations/20260521_order_completed_webhook.sql`
```sql
-- Migration: Add webhook trigger for completed orders
-- Date: 2026-05-21
--
-- هذا الملف يُنشئ تريجر (Trigger) في قاعدة البيانات يقوم باستدعاء رابط الويب هوك (Webhook)
-- الخاص بتطبيق الويب عندما يتم تحديث حالة الطلب إلى 'completed' (مكتمل).
--

-- 1. التأكد من وجود كود التريجر وحذفه إن وجد مسبقاً لمنع التكرار
DROP TRIGGER IF EXISTS on_order_completed ON public.orders;
DROP FUNCTION IF EXISTS public.handle_order_completed();

-- 2. إنشاء وظيفة التريجر التي تقوم بإرسال الطلب (HTTP POST) عبر إرسال غير متزامن
CREATE OR REPLACE FUNCTION public.handle_order_completed()
RETURNS TRIGGER AS $$
DECLARE
    webhook_url TEXT := 'http://localhost:3000/api/webhooks/order-completed'; -- يستبدل برابط الإنتاج الفعلي لاحقاً
    webhook_secret TEXT := 'tamm_webhook_secret_2026_secure'; -- يجب أن يطابق قيمة SUPABASE_WEBHOOK_SECRET
BEGIN
    -- تشغيل الويب هوك فقط عند انتقال حالة الطلب إلى 'completed' (مكتمل)
    IF (NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status <> 'completed')) THEN
        -- نقوم باستخدام إرسال HTTP Asynchronous عبر إضافة net الخاصة بـ Supabase
        PERFORM net.http_post(
            url := webhook_url,
            headers := json_build_object(
                'Content-Type', 'application/json',
                'x-webhook-secret', webhook_secret
            )::jsonb,
            body := json_build_object(
                'type', TG_OP,
                'table', TG_TABLE_NAME,
                'schema', TG_TABLE_SCHEMA,
                'record', row_to_json(NEW),
                'old_record', row_to_json(OLD)
            )::text
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. ربط الوظيفة بالجدول للتفعيل عند التحديث
CREATE TRIGGER on_order_completed
AFTER UPDATE ON public.orders
FOR EACH ROW
EXECUTE FUNCTION public.handle_order_completed();
```

### ج. كود معالج الويب هوك في تطبيق Next.js
**الملف:** `app/api/webhooks/order-completed/route.ts`
```typescript
import { NextResponse } from 'next/server'
import { createInvoiceForOrderAdmin } from '@/lib/actions/admin/invoices'
import { calculateCommissionForOrder } from '@/lib/actions/admin/commissions'

export async function POST(request: Request) {
  try {
    // 1. التحقق من سرية الهوك لحماية المسار
    const secretHeader = request.headers.get('x-webhook-secret')
    const localSecret = process.env.SUPABASE_WEBHOOK_SECRET

    if (!localSecret || secretHeader !== localSecret) {
      console.warn('[Webhook] محاولة وصول غير مصرح بها أو إعدادات السرية مفقودة')
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    // 2. تحليل محتوى الطلب (Supabase Trigger Payload)
    const payload = await request.json()
    const { type, table, record, old_record } = payload

    console.log(`[Webhook] تم استلام هوك لجدول: ${table} من نوع: ${type}`)

    if (table !== 'orders') {
      return NextResponse.json({ message: 'Table not supported' }, { status: 200 })
    }

    // 3. التحقق من انتقال حالة الطلب إلى 'completed'
    const isCompleted = record?.status === 'completed'
    const wasAlreadyCompleted = old_record?.status === 'completed'

    if (isCompleted && !wasAlreadyCompleted) {
      const orderId = record.id
      console.log(`[Webhook] معالجة الطلب المكتمل: ${orderId}`)

      // تشغيل توليد الفاتورة بصلاحيات المسؤول
      const invoiceResult = await createInvoiceForOrderAdmin(orderId)
      if (invoiceResult.error) {
        console.error(`[Webhook] خطأ أثناء إنشاء الفاتورة للطلب ${orderId}:`, invoiceResult.error)
      } else {
        console.log(`[Webhook] تم إنشاء الفاتورة بنجاح للطلب: ${orderId}`)
      }

      // تشغيل حساب عمولة الفني
      const commissionResult = await calculateCommissionForOrder(orderId)
      if (commissionResult.error) {
        console.error(`[Webhook] خطأ أثناء حساب العمولة للطلب ${orderId}:`, commissionResult.error)
      } else {
        console.log(`[Webhook] تم حساب وتسجيل العمولة بنجاح للطلب: ${orderId}`)
      }

      return NextResponse.json({
        success: true,
        orderId,
        invoiceCreated: !invoiceResult.error,
        commissionCalculated: !commissionResult.error,
      }, { status: 200 })
    }

    return NextResponse.json({
      success: true,
      message: 'No actions performed (order status not transitioning to completed)',
    }, { status: 200 })
  } catch (err: any) {
    console.error('[Webhook Error]:', err.message || err)
    return NextResponse.json({ error: 'Internal Server Error', details: err.message }, { status: 500 })
  }
}
```

### د. جزء التحكم في تعيين الفنيين وعرض واجهة التوصيل فقط
**الملف:** `components/admin/orders/AdminOrderActions.tsx` (الأجزاء الخاصة بالتحكم بـ `isDeliveryOnly`)
```typescript
// ... داخل المكون AdminOrderActions ...

// طلب منتجات بدون تركيب ← سير التوصيل لا يحتاج تعيين فني
const isDeliveryOnly =
  order.orderType === 'product' &&
  (order.items?.length ?? 0) > 0 &&
  order.items.every((it) => !it.includeInstallation)

// ...

return (
  <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
    
    {/* ... رسائل النجاح والخطأ ... */}

    {/* ── سير التوصيل لطلبات المنتجات بدون تركيب ── */}
    {isDeliveryOnly && order.status !== 'cancelled' && (
      <div style={cardStyle}>
        <h3 style={{ margin: '0 0 1rem', fontSize: '1rem', fontWeight: 700, color: 'var(--text-primary)', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <span>📦</span>
          <span>إدارة التوصيل</span>
        </h3>
        <p style={{ margin: '0 0 1.25rem', fontSize: '0.825rem', color: 'var(--text-second)', lineHeight: 1.5 }}>
          هذا الطلب لا يتضمن تركيباً، فلا يحتاج تعيين فني. تابع الحالة عبر الأزرار التالية.
        </p>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
          {order.status === 'pending' && (
            <button
              onClick={() => advanceDeliveryStatus('confirmed', 'تم تأكيد الطلب ✓')}
              disabled={loading}
              style={{ ...btnPrimary, opacity: loading ? 0.6 : 1 }}
            >
              {loading ? 'جاري التأكيد...' : '✓ تأكيد الطلب'}
            </button>
          )}

          {order.status === 'confirmed' && (
            <button
              onClick={() => advanceDeliveryStatus('on_the_way', 'الموصل تحرّك إلى العميل ✓')}
              disabled={loading}
              style={{ ...btnPrimary, opacity: loading ? 0.6 : 1 }}
            >
              {loading ? 'جاري التحديث...' : '🚚 بدء التوصيل'}
            </button>
          )}

          {order.status === 'on_the_way' && (
            <button
              onClick={() => advanceDeliveryStatus('completed', 'تم تسليم الطلب بنجاح ✓')}
              disabled={loading}
              style={{
                ...btnPrimary,
                background: 'linear-gradient(135deg, var(--success), #16a34a)',
                opacity: loading ? 0.6 : 1,
              }}
            >
              {loading ? 'جاري التحديث...' : '📬 تم التسليم'}
            </button>
          )}

          {/* ... حالات الحماية الأخرى ... */}
        </div>
      </div>
    )}

    {/* ── تعيين الفني (pending / confirmed) — يُخفى لطلبات التوصيل البحتة ── */}
    {!isDeliveryOnly && (order.status === 'pending' || order.status === 'confirmed') && (
      <div style={cardStyle}>
        <h3 style={{ margin: '0 0 1.25rem', fontSize: '1rem', fontWeight: 700, color: 'var(--text-primary)' }}>
          👷 تعيين الفني
        </h3>
        {/* ... نموذج تعيين الفني واختيار الموعد والتوجيهات ... */}
      </div>
    )}

    {/* ... كرت تفاصيل التعيين الحالي ... */}

  </div>
)
```
