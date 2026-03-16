import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../shared/providers/order_providers.dart';

class BookingConfirmationScreen extends ConsumerWidget {
  final String orderId;

  const BookingConfirmationScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: const TammAppBar(title: 'تأكيد الحجز'),
      body: orderAsync.when(
        data: (order) {
          final serviceName = order.items.isNotEmpty 
              ? order.items.first.itemType // It would be better to get the actual service name, but itemType is a fallback
              : 'الخدمة';
          
          return SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                
                // Success Badge
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 80,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  'تمّ حجزك بنجاح!',
                  style: GoogleFonts.harmattan(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'رقم الطلب: ${order.orderNumber}',
                  style: GoogleFonts.harmattan(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecond,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Summary Card
                TammCard(
                  child: Column(
                    children: [
                      _SummaryRow(
                        title: 'الخدمة المختارة',
                        value: serviceName, // Optionally show 'order.items.first.service_type_id' resolved, but we skip it here
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: AppColors.border),
                      ),
                      if (order.scheduledPeriod != null) ...[
                        _SummaryRow(
                          title: 'الموعد',
                          value: '${order.preferredDate != null ? "${order.preferredDate!.day}/${order.preferredDate!.month} — " : ""}${order.scheduledPeriod} ${order.scheduledHour ?? ''}',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: AppColors.border),
                        ),
                      ],
                      _SummaryRow(
                        title: 'الموقع',
                        value: order.address,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  'سيتواصل معك الفني قريباً لتأكيد الموعد.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.harmattan(
                    fontSize: 18,
                    color: AppColors.bluePrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                TammButton(
                  label: 'تتبع الطلب',
                  icon: Icons.local_shipping_outlined,
                  onPressed: () => context.push('/customer/order/$orderId'),
                ),
                
                const SizedBox(height: 16),
                
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
        error: (e, _) => Center(child: Text('حدث خطأ: $e')),
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
            style: GoogleFonts.harmattan(
              fontSize: 16,
              color: AppColors.textSecond,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.harmattan(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
