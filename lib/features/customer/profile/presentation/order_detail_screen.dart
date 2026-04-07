import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../shared/models/order.dart';
import '../../../../shared/providers/order_providers.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: const TammAppBar(title: 'تفاصيل الطلب'),
      body: orderAsync.when(
        data: (o) => _buildBody(context, o),
        loading: () => const TammLoading(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Order o) {
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
                                style: GoogleFonts.harmattan(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '#${o.orderNumber}',
                                style: GoogleFonts.harmattan(
                                  fontSize: 14,
                                  color: AppColors.textSecond,
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
                              style: GoogleFonts.harmattan(
                                fontSize: 14,
                                color: _getStatusColor(o),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: AppColors.border),
                      _InfoRow(icon: Icons.location_on, text: o.address),
                      if (o.preferredDate != null)
                        _InfoRow(
                          icon: Icons.calendar_today,
                          text: '${o.preferredDate!.day}/${o.preferredDate!.month}/${o.preferredDate!.year}',
                        ),
                      if (o.scheduledPeriod != null)
                        _InfoRow(icon: Icons.access_time, text: '${o.scheduledPeriod!} ${o.scheduledHour ?? ''}'),
                      if (o.notes != null && o.notes!.isNotEmpty)
                        _InfoRow(icon: Icons.note, text: o.notes!),
                      if (o.technicianName != null)
                        _InfoRow(icon: Icons.engineering, text: 'الفني: ${o.technicianName!}'),
                      if (o.technicianNotes != null && o.technicianNotes!.isNotEmpty)
                        _InfoRow(icon: Icons.fact_check, text: 'تقرير الفني: ${o.technicianNotes!}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quote Details Section (for quote_request orders)
                if (o.orderType == 'quote_request' && o.quoteStatus == 'sent') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.bluePrimary.withValues(alpha: 0.08),
                          AppColors.blueSky.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: AppSpacing.radiusLg,
                      border: Border.all(color: AppColors.bluePrimary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.local_offer, color: AppColors.bluePrimary, size: 36),
                        const SizedBox(height: 8),
                        Text(
                          'تم استلام عرض السعر!',
                          style: GoogleFonts.harmattan(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'السعر: ${o.quotePrice?.toInt() ?? 0} ر.س',
                          style: GoogleFonts.harmattan(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blueSky,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TammButton(
                          label: 'عرض التفاصيل والرد',
                          icon: Icons.reply,
                          onPressed: () => context.push('/customer/quote-response/${o.id}'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (o.orderType == 'quote_request' && o.quoteStatus == 'pending') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: AppSpacing.radiusLg,
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_top, color: AppColors.warning, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'بانتظار عرض السعر',
                                style: GoogleFonts.harmattan(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'يقوم فريقنا بمراجعة طلبك وسيتم إرسال العرض قريباً',
                                style: GoogleFonts.harmattan(
                                  fontSize: 14,
                                  color: AppColors.textSecond,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (o.orderType == 'quote_request' && o.quoteStatus == 'accepted') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: AppSpacing.radiusLg,
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تم قبول العرض',
                                style: GoogleFonts.harmattan(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                              Text(
                                'السعر المتفق عليه: ${o.quotePrice?.toInt() ?? 0} ر.س',
                                style: GoogleFonts.harmattan(
                                  fontSize: 14,
                                  color: AppColors.textSecond,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Items
                Text(
                  'العناصر',
                  style: GoogleFonts.harmattan(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...o.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TammCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item.itemType == 'product' ? 'منتج' : 'خدمة'} × ${item.quantity}',
                            style: GoogleFonts.harmattan(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            item.totalPrice > 0
                                ? '${item.totalPrice.toInt()} ر.س'
                                : 'عرض سعر',
                            style: GoogleFonts.harmattan(
                              color: AppColors.blueSky,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Total
                if (o.totalAmount > 0 || (o.orderType == 'quote_request' && o.quotePrice != null))
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'المجموع',
                        style: GoogleFonts.harmattan(
                          fontSize: 18,
                          color: AppColors.textSecond,
                        ),
                      ),
                      Text(
                        '${(o.orderType == 'quote_request' ? (o.quotePrice ?? 0) : o.totalAmount).toInt()} ر.س',
                        style: GoogleFonts.harmattan(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blueSky,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(Order o) {
    if (o.orderType == 'quote_request') {
      return switch (o.quoteStatus) {
        'pending' => AppColors.warning,
        'sent' => AppColors.bluePrimary,
        'accepted' => AppColors.success,
        'rejected' => AppColors.error,
        _ => AppColors.textSecond,
      };
    }
    return switch (o.status) {
      'pending' => AppColors.warning,
      'confirmed' => AppColors.bluePrimary,
      'assigned' || 'on_the_way' => AppColors.blueLight,
      'in_progress' => AppColors.bluePrimary,
      'completed' => AppColors.success,
      'cancelled' => AppColors.error,
      _ => AppColors.textSecond,
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
          Icon(icon, size: 18, color: AppColors.textSecond),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.harmattan(
                fontSize: 15,
                color: AppColors.textSecond,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
