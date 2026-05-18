import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../shared/models/order.dart';
import '../../../../shared/providers/order_providers.dart';
import '../widgets/order_timeline.dart';
import '../widgets/receipt_upload_widget.dart';
import '../widgets/review_card.dart';

Color _orderStatusColor(BuildContext context, Order o) {
  if (o.orderType == 'quote_request') {
    return switch (o.quoteStatus) {
      'pending' => context.colors.warning,
      'sent' => context.colors.bluePrimary,
      'accepted' => context.colors.success,
      'rejected' => context.colors.error,
      _ => context.colors.textSecond,
    };
  }
  return switch (o.status) {
    'pending' => context.colors.warning,
    'confirmed' => context.colors.bluePrimary,
    'assigned' || 'on_the_way' => context.colors.blueLight,
    'in_progress' => context.colors.bluePrimary,
    'completed' => context.colors.success,
    'cancelled' => context.colors.error,
    _ => context.colors.textSecond,
  };
}

// ─── Custom AppBar ────────────────────────────────────────────────────────────

class _OrderDetailAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final Order order;
  const _OrderDetailAppBar({required this.order});

  @override
  State<_OrderDetailAppBar> createState() => _OrderDetailAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(AppSpacing.appBarHeight + 4);
}

class _OrderDetailAppBarState extends State<_OrderDetailAppBar> {
  bool _copied = false;

  void _copyOrderNumber() {
    Clipboard.setData(ClipboardData(text: widget.order.orderNumber));
    setState(() => _copied = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _orderStatusColor(context, widget.order);
    return AppBar(
      backgroundColor: context.colors.bgSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: AppSpacing.sm,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.order.orderTypeLabel,
            style: AppTextStyles.cardTitle(context.colors.textPrimary),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '#${widget.order.orderNumber}',
                style: AppTextStyles.bodySmall(context.colors.textSecond),
              ),
              AppSpacing.hGapXs,
              GestureDetector(
                onTap: _copyOrderNumber,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _copied
                        ? Icons.check_circle_outlined
                        : Icons.copy_outlined,
                    key: ValueKey(_copied),
                    size: AppSpacing.iconXs,
                    color: _copied
                        ? context.colors.success
                        : context.colors.textFaint,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(
            right: AppSpacing.md,
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm2,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: AppSpacing.radiusFull,
            ),
            child: Text(
              widget.order.statusLabel,
              style: AppTextStyles.caption(statusColor).copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _channel = Supabase.instance.client
        .channel('public:order_${widget.orderId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.orderId,
          ),
          callback: (_) {
            ref.invalidate(orderDetailProvider(widget.orderId));
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: orderAsync.maybeWhen(
        data: (o) => _OrderDetailAppBar(order: o),
        orElse: () => AppBar(
          backgroundColor: context.colors.bgSurface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'تفاصيل الطلب',
            style: AppTextStyles.cardTitle(context.colors.textPrimary),
          ),
        ),
      ),
      body: orderAsync.when(
        data: (o) => _buildBody(context, o),
        loading: () => const TammLoading(),
        error: (e, _) => ErrorStateWidget(
          message: e is AppException ? e.message : 'حدث خطأ في تحميل الطلب',
          onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId)),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Order o) {
    final bottomBar = _buildBottomBar(context, o);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Timeline
                OrderTimeline(currentStatus: o.status),
                AppSpacing.gapMd,

                // 2. Quote section (quote_request orders only)
                if (o.orderType == 'quote_request') ...[
                  _buildQuoteSection(context, o),
                  AppSpacing.gapMd,
                ],

                // 3. Order info (address, date, time, notes, technician)
                _buildDeliverySection(context, o),
                AppSpacing.gapMd,

                // 4. Items
                _buildItemsSection(context, o),

                // 5. Total
                if (o.totalAmount > 0 ||
                    (o.orderType == 'quote_request' &&
                        o.quotePrice != null)) ...[
                  AppSpacing.gapSm2,
                  _buildTotalRow(context, o),
                ],

                // 6. Payment + Receipt (non-quote orders only)
                if (o.orderType != 'quote_request') ...[
                  AppSpacing.gapMd,
                  _PaymentSection(order: o),
                  if (o.paymentType == 'bank' ||
                      o.paymentType == 'wallet') ...[
                    AppSpacing.gapMd,
                    ReceiptUploadWidget(
                      orderId: o.id,
                      orderNumber: o.orderNumber,
                      initialReceiptUrl: o.receiptUrl,
                    ),
                  ],
                ],

                // Review card — only for completed orders
                if (o.status == 'completed') ...[
                  AppSpacing.gapMd,
                  ReviewCard(
                    orderId: o.id,
                    technicianId: o.technicianId,
                  ),
                ],

                AppSpacing.gapXl,
              ],
            ),
          ),
        ),
        if (bottomBar != null) bottomBar,
      ],
    );
  }

  // ─── Quote section ──────────────────────────────────────────────────────────

  Widget _buildQuoteSection(BuildContext context, Order o) {
    if (o.quoteStatus == 'sent') {
      return _InfoCard(
        color: context.colors.bluePrimary,
        icon: Icons.local_offer_outlined,
        title: 'تم استلام عرض السعر!',
        body: 'السعر: ${o.quotePrice?.toInt() ?? 0} ر.س — اضغط على الزر أدناه للرد',
      );
    }
    if (o.quoteStatus == 'accepted') {
      return _InfoCard(
        color: context.colors.success,
        icon: Icons.check_circle_outlined,
        title: 'تم قبول العرض',
        body: 'السعر المتفق عليه: ${o.quotePrice?.toInt() ?? 0} ر.س',
      );
    }
    if (o.quoteStatus == 'rejected') {
      return _InfoCard(
        color: context.colors.error,
        icon: Icons.cancel_outlined,
        title: 'تم رفض العرض',
        body:
            'تم إرسال رفضك للمدير. سيتم مراجعته وإرسال عرض جديد قريباً.',
      );
    }
    // pending (default)
    return _InfoCard(
      color: context.colors.warning,
      icon: Icons.hourglass_top_outlined,
      title: 'بانتظار عرض السعر',
      body: 'يقوم فريقنا بمراجعة طلبك وسيتم إرسال العرض قريباً',
    );
  }

  // ─── Delivery / order info ──────────────────────────────────────────────────

  Widget _buildDeliverySection(BuildContext context, Order o) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تفاصيل الطلب',
            style: AppTextStyles.cardTitle(context.colors.textPrimary),
          ),
          AppSpacing.gapSm2,
          _InfoRow(icon: Icons.location_on_outlined, text: o.address),
          if (o.preferredDate != null)
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              text:
                  '${o.preferredDate!.day}/${o.preferredDate!.month}/${o.preferredDate!.year}',
            ),
          if (o.scheduledPeriod != null)
            _InfoRow(
              icon: Icons.access_time_outlined,
              text: '${o.scheduledPeriod!} ${o.scheduledHour ?? ''}'.trim(),
            ),
          if (o.notes != null && o.notes!.isNotEmpty)
            _InfoRow(icon: Icons.note_outlined, text: o.notes!),
          if (o.technicianName != null)
            _InfoRow(
              icon: Icons.engineering_outlined,
              text: 'الفني: ${o.technicianName!}',
            ),
          if (o.technicianNotes != null && o.technicianNotes!.isNotEmpty)
            _InfoRow(
              icon: Icons.fact_check_outlined,
              text: 'تقرير الفني: ${o.technicianNotes!}',
            ),
        ],
      ),
    );
  }

  // ─── Items ──────────────────────────────────────────────────────────────────

  Widget _buildItemsSection(BuildContext context, Order o) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'العناصر',
          style: AppTextStyles.cardTitle(context.colors.textPrimary),
        ),
        AppSpacing.gapSm,
        ...o.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Container(
              padding: AppSpacing.cardPaddingSm,
              decoration: BoxDecoration(
                color: context.colors.bgSurface,
                borderRadius: AppSpacing.radiusLg,
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.itemType == 'product' ? 'منتج' : 'خدمة'} × ${item.quantity}',
                        style: AppTextStyles.body(context.colors.textPrimary),
                      ),
                      if (item.includeInstallation) ...[
                        AppSpacing.gapXs,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs / 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.success.withValues(alpha: 0.1),
                            borderRadius: AppSpacing.radiusXs,
                          ),
                          child: Text(
                            'شامل التركيب',
                            style: AppTextStyles.caption(context.colors.success),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    item.totalPrice > 0
                        ? '${item.totalPrice.toInt()} ر.س'
                        : 'عرض سعر',
                    style: AppTextStyles.body(context.colors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Total ──────────────────────────────────────────────────────────────────

  Widget _buildTotalRow(BuildContext context, Order o) {
    final amount = o.orderType == 'quote_request'
        ? (o.quotePrice ?? 0)
        : o.totalAmount;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'المجموع',
          style: AppTextStyles.body(context.colors.textPrimary),
        ),
        Text(
          '${amount.toInt()} ر.س',
          style: AppTextStyles.body(
            context.colors.textPrimary,
          ).copyWith(fontWeight: AppTextStyles.semiBold),
        ),
      ],
    );
  }

  // ─── Bottom action bar ──────────────────────────────────────────────────────

  Widget? _buildBottomBar(BuildContext context, Order o) {
    if (o.orderType == 'quote_request' && o.quoteStatus == 'sent') {
      return _BottomActionBar(
        child: TammButton(
          label: 'عرض التفاصيل والرد',
          icon: Icons.reply_outlined,
          onPressed: () => context.push('/customer/quote-response/${o.id}'),
        ),
      );
    }
    if (o.status == 'completed') {
      return _BottomActionBar(
        child: TammButton(
          label: 'طلب خدمة جديدة',
          icon: Icons.add_circle_outlined,
          onPressed: () => context.go('/customer/home'),
        ),
      );
    }
    if (o.status == 'cancelled') {
      return _BottomActionBar(
        child: TammButton(
          label: 'تقديم طلب جديد',
          icon: Icons.refresh_outlined,
          onPressed: () => context.go('/customer/home'),
        ),
      );
    }
    return null;
  }
}

// ─── Info card (quote states) ─────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String body;

  const _InfoCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: AppSpacing.iconLg),
          AppSpacing.hGapSm2,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body(context.colors.textPrimary)
                      .copyWith(fontWeight: AppTextStyles.bold),
                ),
                AppSpacing.gapXs,
                Text(
                  body,
                  style: AppTextStyles.bodySmall(context.colors.textSecond),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSpacing.iconXs + 2, color: context.colors.textSecond),
          AppSpacing.hGapSm,
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body(context.colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom action bar container ──────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  final Widget child;
  const _BottomActionBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.pagePadding,
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        border: Border(top: BorderSide(color: context.colors.border)),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}

// ─── Payment section ──────────────────────────────────────────────────────────

class _PaymentSection extends ConsumerWidget {
  final Order order;
  const _PaymentSection({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'طريقة الدفع',
          style: AppTextStyles.cardTitle(context.colors.textPrimary),
        ),
        AppSpacing.gapSm,
        Container(
          width: double.infinity,
          padding: AppSpacing.cardPaddingSm,
          decoration: BoxDecoration(
            color: context.colors.bgSurface,
            borderRadius: AppSpacing.radius,
            border: Border.all(color: context.colors.border),
          ),
          child: order.paymentType == 'cash'
              ? _CashRow()
              : order.paymentMethodId != null
                  ? _MethodDisplay(
                      methodId: order.paymentMethodId!,
                      type: order.paymentType,
                    )
                  : _FallbackPaymentRow(type: order.paymentType),
        ),
      ],
    );
  }
}

class _CashRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.payments_outlined,
          color: context.colors.success,
          size: AppSpacing.iconMd,
        ),
        AppSpacing.hGapSm2,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'كاش عند الاستلام',
              style: AppTextStyles.body(
                context.colors.textPrimary,
              ).copyWith(fontWeight: AppTextStyles.semiBold),
            ),
            AppSpacing.gapXs,
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs / 2,
              ),
              decoration: BoxDecoration(
                color: context.colors.success.withValues(alpha: 0.1),
                borderRadius: AppSpacing.radiusFull,
              ),
              child: Text(
                'لا يلزم تحويل',
                style: AppTextStyles.caption(context.colors.success),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FallbackPaymentRow extends StatelessWidget {
  final String type;
  const _FallbackPaymentRow({required this.type});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          type == 'bank'
              ? Icons.account_balance_outlined
              : Icons.account_balance_wallet_outlined,
          color: context.colors.bluePrimary,
          size: AppSpacing.iconMd,
        ),
        AppSpacing.hGapSm2,
        Text(
          type == 'bank' ? 'تحويل بنكي' : 'محفظة إلكترونية',
          style: AppTextStyles.body(context.colors.textPrimary),
        ),
      ],
    );
  }
}

class _MethodDisplay extends ConsumerStatefulWidget {
  final String methodId;
  final String type;
  const _MethodDisplay({required this.methodId, required this.type});

  @override
  ConsumerState<_MethodDisplay> createState() => _MethodDisplayState();
}

class _MethodDisplayState extends ConsumerState<_MethodDisplay> {
  bool _copied = false;

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final methodAsync = ref.watch(paymentMethodByIdProvider(widget.methodId));
    final fallbackLabel =
        widget.type == 'bank' ? 'تحويل بنكي' : 'محفظة إلكترونية';
    final fallbackIcon = widget.type == 'bank'
        ? Icons.account_balance_outlined
        : Icons.account_balance_wallet_outlined;

    return methodAsync.when(
      data: (method) {
        final accountNumber = method?['account_number'] as String?;
        return Row(
          children: [
            Icon(
              fallbackIcon,
              color: context.colors.bluePrimary,
              size: AppSpacing.iconMd,
            ),
            AppSpacing.hGapSm2,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method?['name'] as String? ?? fallbackLabel,
                    style: AppTextStyles.body(
                      context.colors.textPrimary,
                    ).copyWith(fontWeight: AppTextStyles.semiBold),
                  ),
                  if (accountNumber != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          accountNumber,
                          style: AppTextStyles.caption(
                            context.colors.textSecond,
                          ),
                        ),
                        AppSpacing.hGapXs,
                        GestureDetector(
                          onTap: () => _copy(accountNumber),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _copied
                                  ? Icons.check_circle_outlined
                                  : Icons.copy_outlined,
                              key: ValueKey(_copied),
                              size: AppSpacing.iconXs,
                              color: _copied
                                  ? context.colors.success
                                  : context.colors.textFaint,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (method?['account_name'] != null)
                    Text(
                      method!['account_name'] as String,
                      style: AppTextStyles.caption(context.colors.textSecond),
                    ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => Row(
        children: [
          Icon(
            fallbackIcon,
            color: context.colors.bluePrimary,
            size: AppSpacing.iconMd,
          ),
          AppSpacing.hGapSm2,
          const SizedBox(
            width: AppSpacing.iconMd,
            height: AppSpacing.iconMd,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
      error: (_, __) => Row(
        children: [
          Icon(
            fallbackIcon,
            color: context.colors.bluePrimary,
            size: AppSpacing.iconMd,
          ),
          AppSpacing.hGapSm2,
          Text(
            fallbackLabel,
            style: AppTextStyles.body(context.colors.textPrimary),
          ),
        ],
      ),
    );
  }
}
