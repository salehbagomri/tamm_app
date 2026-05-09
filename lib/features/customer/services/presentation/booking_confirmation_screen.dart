import '../../../../core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../shared/providers/order_providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class BookingConfirmationScreen extends ConsumerWidget {
  final String orderId;

  const BookingConfirmationScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: const TammAppBar(title: 'تأكيد الحجز'),
      body: orderAsync.when(
        data: (order) {
          final serviceName = order.items.isNotEmpty
              ? order
                    .items
                    .first
                    .itemType // It would be better to get the actual service name, but itemType is a fallback
              : 'الخدمة';

          return SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppSpacing.gapXl,

                // Success Badge
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: context.colors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: context.colors.success,
                    size: 80,
                  ),
                ),

                AppSpacing.gapLg,

                Text(
                  'تمّ حجزك بنجاح!',
                  style: AppTextStyles.body(context.colors.textPrimary),
                ),

                AppSpacing.gapSm,

                Text(
                  'رقم الطلب: ${order.orderNumber}',
                  style: AppTextStyles.cardTitle(context.colors.textSecond),
                ),

                AppSpacing.gapXl,

                // Summary Card
                TammCard(
                  child: Column(
                    children: [
                      _SummaryRow(
                        title: 'الخدمة المختارة',
                        value:
                            serviceName, // Optionally show 'order.items.first.service_type_id' resolved, but we skip it here
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: context.colors.border),
                      ),
                      if (order.scheduledPeriod != null) ...[
                        _SummaryRow(
                          title: 'الموعد',
                          value:
                              '${order.preferredDate != null ? "${order.preferredDate!.day}/${order.preferredDate!.month} — " : ""}${order.scheduledPeriod} ${order.scheduledHour ?? ''}',
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: context.colors.border),
                        ),
                      ],
                      _SummaryRow(title: 'الموقع', value: order.address),
                    ],
                  ),
                ),

                AppSpacing.gapXl,

                Text(
                  'سيتواصل معك الفني قريباً لتأكيد الموعد.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(context.colors.textPrimary),
                ),

                const SizedBox(height: 48),

                TammButton(
                  label: 'تتبع الطلب',
                  icon: Icons.local_shipping_outlined,
                  onPressed: () => context.push('/customer/order/$orderId'),
                ),

                AppSpacing.gapMd,

                TammButton(
                  label: 'العودة للرئيسية',
                  type: TammButtonType.secondary,
                  onPressed: () => context.go('/customer/home'),
                ),
              ],
            ),
          );
        },
        loading: () => const TammLoading(),
        error: (e, _) => ErrorStateWidget(
          message: e is AppException
              ? e.message
              : 'حدث خطأ في تحميل بيانات الحجز',
          onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: AppTextStyles.body(context.colors.textSecond),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: AppTextStyles.body(
              context.colors.textPrimary,
            ).copyWith(fontWeight: AppTextStyles.bold),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
