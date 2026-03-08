import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_card.dart';
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
        data: (o) => SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TammCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          o.orderNumber,
                          style: GoogleFonts.harmattan(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bluePrimary.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: AppSpacing.radiusFull,
                          ),
                          child: Text(
                            o.statusLabel,
                            style: GoogleFonts.harmattan(
                              fontSize: 12,
                              color: AppColors.bluePrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'العنوان: ${o.address}',
                      style: GoogleFonts.harmattan(color: AppColors.textSecond),
                    ),
                    if (o.preferredDate != null)
                      Text(
                        'الموعد: ${o.preferredDate!.day}/${o.preferredDate!.month}/${o.preferredDate!.year}',
                        style: GoogleFonts.harmattan(
                          color: AppColors.textSecond,
                        ),
                      ),
                    if (o.notes != null)
                      Text(
                        'ملاحظات: ${o.notes}',
                        style: GoogleFonts.harmattan(
                          color: AppColors.textSecond,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                          '${item.totalPrice.toInt()} ريال',
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
                    '${o.totalAmount.toInt()} ريال',
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
        loading: () => const TammLoading(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
