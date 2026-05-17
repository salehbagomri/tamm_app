import '../../../../core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../shared/models/order.dart';
import '../../../../shared/providers/order_providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';
import '../widgets/receipt_upload_widget.dart';

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
      appBar: const TammAppBar(title: 'تفاصيل الطلب'),
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
    final isQuotePhase =
        o.orderType == 'quote_request' &&
        (o.status == 'pending' || o.status == 'confirmed');
    final isExecutionPhase =
        o.orderType == 'quote_request' &&
        [
          'assigned',
          'on_the_way',
          'in_progress',
          'completed',
        ].contains(o.status);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Header
                TammCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                o.orderTypeLabel,
                                style: AppTextStyles.sectionTitle(
                                  context.colors.textPrimary,
                                ),
                              ),
                              Text(
                                '#${o.orderNumber}',
                                style: AppTextStyles.bodySmall(
                                  context.colors.textSecond,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(o).withValues(alpha: 0.15),
                              borderRadius: AppSpacing.radiusFull,
                            ),
                            child: Text(
                              o.statusLabel,
                              style: AppTextStyles.bodySmall(
                                _getStatusColor(o),
                              ).copyWith(fontWeight: AppTextStyles.bold),
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 24, color: context.colors.border),
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
                          text:
                              '${o.scheduledPeriod!} ${o.scheduledHour ?? ''}',
                        ),
                      if (o.notes != null && o.notes!.isNotEmpty)
                        _InfoRow(icon: Icons.note, text: o.notes!),
                      if (o.technicianName != null)
                        _InfoRow(
                          icon: Icons.engineering_outlined,
                          text: 'الفني: ${o.technicianName!}',
                        ),
                      if (o.technicianNotes != null &&
                          o.technicianNotes!.isNotEmpty)
                        _InfoRow(
                          icon: Icons.fact_check_outlined,
                          text: 'تقرير الفني: ${o.technicianNotes!}',
                        ),
                    ],
                  ),
                ),
                AppSpacing.gapMd,

                // Quote Details Section (for quote_request orders in quote phase)
                if (isQuotePhase) ...[
                  if (o.quoteStatus == 'sent') ...[
                    Container(
                      width: double.infinity,
                      padding: AppSpacing.cardPadding,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            context.colors.bluePrimary.withValues(alpha: 0.08),
                            context.colors.blueSky.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: AppSpacing.radiusLg,
                        border: Border.all(
                          color: context.colors.bluePrimary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.local_offer_outlined,
                            color: context.colors.bluePrimary,
                            size: 36,
                          ),
                          AppSpacing.gapSm,
                          Text(
                            'تم استلام عرض السعر!',
                            style: AppTextStyles.cardTitle(
                              context.colors.textPrimary,
                            ),
                          ),
                          AppSpacing.gapXs,
                          Text(
                            'السعر: ${o.quotePrice?.toInt() ?? 0} ر.س',
                            style: AppTextStyles.body(
                              context.colors.textPrimary,
                            ),
                          ),
                          AppSpacing.gapMd,
                          TammButton(
                            label: 'عرض التفاصيل والرد',
                            icon: Icons.reply_outlined,
                            onPressed: () => context.push(
                              '/customer/quote-response/${o.id}',
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapMd,
                  ] else if (o.quoteStatus == 'pending') ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.radiusXlValue),
                      decoration: BoxDecoration(
                        color: context.colors.warning.withValues(alpha: 0.08),
                        borderRadius: AppSpacing.radiusLg,
                        border: Border.all(
                          color: context.colors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.hourglass_top,
                            color: context.colors.warning,
                            size: 32,
                          ),
                          AppSpacing.hGapMd,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'بانتظار عرض السعر',
                                  style: AppTextStyles.body(
                                    context.colors.textPrimary,
                                  ).copyWith(fontWeight: AppTextStyles.bold),
                                ),
                                Text(
                                  'يقوم فريقنا بمراجعة طلبك وسيتم إرسال العرض قريباً',
                                  style: AppTextStyles.bodySmall(
                                    context.colors.textSecond,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapMd,
                  ] else if (o.quoteStatus == 'accepted') ...[
                    Container(
                      width: double.infinity,
                      padding: AppSpacing.cardPadding,
                      decoration: BoxDecoration(
                        color: context.colors.success.withValues(alpha: 0.08),
                        borderRadius: AppSpacing.radiusLg,
                        border: Border.all(
                          color: context.colors.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: context.colors.success,
                            size: 32,
                          ),
                          AppSpacing.hGapMd,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تم قبول العرض',
                                  style: AppTextStyles.body(
                                    context.colors.success,
                                  ).copyWith(fontWeight: AppTextStyles.bold),
                                ),
                                Text(
                                  'السعر المتفق عليه: ${o.quotePrice?.toInt() ?? 0} ر.س',
                                  style: AppTextStyles.bodySmall(
                                    context.colors.textSecond,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapMd,
                  ] else if (o.quoteStatus == 'rejected') ...[
                    Container(
                      width: double.infinity,
                      padding: AppSpacing.cardPadding,
                      decoration: BoxDecoration(
                        color: context.colors.error.withValues(alpha: 0.08),
                        borderRadius: AppSpacing.radiusLg,
                        border: Border.all(
                          color: context.colors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cancel,
                            color: context.colors.error,
                            size: 32,
                          ),
                          AppSpacing.hGapMd,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تم رفض العرض',
                                  style: AppTextStyles.body(
                                    context.colors.error,
                                  ).copyWith(fontWeight: AppTextStyles.bold),
                                ),
                                Text(
                                  'تم إرسال رفضك للمدير. سيتم مراجعته وإرسال عرض جديد قريباً.',
                                  style: AppTextStyles.bodySmall(
                                    context.colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapMd,
                  ],
                ],

                if (isExecutionPhase ||
                    (o.orderType != 'quote_request' &&
                        [
                          'assigned',
                          'on_the_way',
                          'in_progress',
                          'completed',
                        ].contains(o.status))) ...[
                  _buildProgressBar(o),
                  AppSpacing.gapMd,
                ],

                // Items
                Text(
                  'العناصر',
                  style: AppTextStyles.cardTitle(context.colors.textPrimary),
                ),
                AppSpacing.gapSm,
                ...o.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TammCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.itemType == 'product' ? 'منتج' : 'خدمة'} × ${item.quantity}',
                                style: AppTextStyles.body(
                                  context.colors.textPrimary,
                                ),
                              ),
                              if (item.includeInstallation) ...[
                                AppSpacing.gapXs,
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: context.colors.success
                                        .withValues(alpha: 0.1),
                                    borderRadius: AppSpacing.radiusXs,
                                  ),
                                  child: Text(
                                    'شامل التركيب',
                                    style: AppTextStyles.caption(
                                        context.colors.success),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            item.totalPrice > 0
                                ? '${item.totalPrice.toInt()} ر.س'
                                : 'عرض سعر',
                            style: AppTextStyles.body(
                              context.colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AppSpacing.gapSm2,

                // Total
                if (o.totalAmount > 0 ||
                    (o.orderType == 'quote_request' && o.quotePrice != null))
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'المجموع',
                        style: AppTextStyles.body(context.colors.textPrimary),
                      ),
                      Text(
                        '${(o.orderType == 'quote_request' ? (o.quotePrice ?? 0) : o.totalAmount).toInt()} ر.س',
                        style: AppTextStyles.body(context.colors.textPrimary),
                      ),
                    ],
                  ),
                if (o.orderType != 'quote_request') ...[
                  AppSpacing.gapMd,
                  _PaymentSection(order: o),
                  if (o.paymentType == 'bank' || o.paymentType == 'wallet') ...[
                    AppSpacing.gapMd,
                    ReceiptUploadWidget(
                      orderId: o.id,
                      initialReceiptUrl: o.receiptUrl,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(Order o) {
    int currentStep = 0;
    if (o.status == 'assigned') currentStep = 1;
    if (o.status == 'on_the_way') currentStep = 2;
    if (o.status == 'in_progress') currentStep = 3;
    if (o.status == 'completed') currentStep = 4;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.radiusXlValue),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'حالة التنفيذ',
            style: AppTextStyles.cardTitle(context.colors.textPrimary),
          ),
          AppSpacing.gapMd,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressStep('تم التعيين', currentStep >= 1, isFirst: true),
              _buildProgressLine(currentStep >= 2),
              _buildProgressStep('في الطريق', currentStep >= 2),
              _buildProgressLine(currentStep >= 3),
              _buildProgressStep('جاري التنفيذ', currentStep >= 3),
              _buildProgressLine(currentStep >= 4),
              _buildProgressStep('مكتمل', currentStep >= 4, isLast: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        color: active ? context.colors.success : context.colors.border,
      ),
    );
  }

  Widget _buildProgressStep(
    String label,
    bool active, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: active ? context.colors.success : context.colors.bgSurface,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? context.colors.success : context.colors.border,
              width: 2,
            ),
          ),
          child: active
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
        AppSpacing.gapSm,
        Text(label, style: AppTextStyles.body(context.colors.textPrimary)),
      ],
    );
  }

  Color _getStatusColor(Order o) {
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
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: context.colors.textSecond),
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

class _PaymentSection extends ConsumerWidget {
  final Order order;
  const _PaymentSection({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCash = order.paymentType == 'cash';
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
          child: isCash
              ? Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      color: context.colors.bluePrimary,
                      size: AppSpacing.iconMd,
                    ),
                    AppSpacing.hGapSm2,
                    Text(
                      'كاش عند الاستلام',
                      style: AppTextStyles.body(context.colors.textPrimary)
                          .copyWith(fontWeight: AppTextStyles.semiBold),
                    ),
                  ],
                )
              : order.paymentMethodId != null
                  ? _MethodDisplay(
                      methodId: order.paymentMethodId!,
                      type: order.paymentType,
                    )
                  : Row(
                      children: [
                        Icon(
                          order.paymentType == 'bank'
                              ? Icons.account_balance_outlined
                              : Icons.account_balance_wallet_outlined,
                          color: context.colors.bluePrimary,
                          size: AppSpacing.iconMd,
                        ),
                        AppSpacing.hGapSm2,
                        Text(
                          order.paymentType == 'bank'
                              ? 'تحويل بنكي'
                              : 'محفظة إلكترونية',
                          style: AppTextStyles.body(context.colors.textPrimary),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }
}

class _MethodDisplay extends ConsumerWidget {
  final String methodId;
  final String type;
  const _MethodDisplay({required this.methodId, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodAsync = ref.watch(paymentMethodByIdProvider(methodId));
    final fallbackLabel =
        type == 'bank' ? 'تحويل بنكي' : 'محفظة إلكترونية';
    final fallbackIcon = type == 'bank'
        ? Icons.account_balance_outlined
        : Icons.account_balance_wallet_outlined;

    return methodAsync.when(
      data: (method) => Row(
        children: [
          Icon(fallbackIcon, color: context.colors.bluePrimary, size: AppSpacing.iconMd),
          AppSpacing.hGapSm2,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method?['name'] as String? ?? fallbackLabel,
                  style: AppTextStyles.body(context.colors.textPrimary)
                      .copyWith(fontWeight: AppTextStyles.semiBold),
                ),
                if (method?['account_number'] != null)
                  Text(
                    method!['account_number'] as String,
                    style: AppTextStyles.caption(context.colors.textSecond),
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
      ),
      loading: () => Row(
        children: [
          Icon(fallbackIcon, color: context.colors.bluePrimary, size: AppSpacing.iconMd),
          AppSpacing.hGapSm2,
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
      error: (_, __) => Row(
        children: [
          Icon(fallbackIcon, color: context.colors.bluePrimary, size: AppSpacing.iconMd),
          AppSpacing.hGapSm2,
          Text(fallbackLabel, style: AppTextStyles.body(context.colors.textPrimary)),
        ],
      ),
    );
  }
}
