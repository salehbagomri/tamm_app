import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/providers/order_providers.dart';

class ActiveOrderCard extends ConsumerWidget {
  const ActiveOrderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrderAsync = ref.watch(activeOrderStreamProvider);

    return activeOrderAsync.when(
      data: (order) {
        if (order == null) return const SizedBox.shrink();
        
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: AppSpacing.radiusLg,
            border: Border.all(color: AppColors.bluePrimary.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.bluePrimary.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.electric_bolt, color: AppColors.blueSky),
                      const SizedBox(width: 8),
                      Text(
                        'طلب نشط',
                        style: GoogleFonts.harmattan(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blueSky,
                        ),
                      ),
                    ],
                  ),
                  _buildStatusBadge(order.status, order.statusLabel),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'رقم الطلب: #${order.orderNumber}',
                style: GoogleFonts.harmattan(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  order.notes!,
                  style: GoogleFonts.harmattan(
                    fontSize: 14,
                    color: AppColors.textSecond,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (order.technicianName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.engineering, size: 16, color: AppColors.textSecond),
                    const SizedBox(width: 4),
                    Text(
                      'الفني: ${order.technicianName}',
                      style: GoogleFonts.harmattan(
                        fontSize: 14,
                        color: AppColors.textSecond,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/customer/order/${order.id}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bluePrimary.withOpacity(0.1),
                    foregroundColor: AppColors.blueSky,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.radiusSm,
                    ),
                  ),
                  child: Text(
                    'تفاصيل الطلب',
                    style: GoogleFonts.harmattan(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatusBadge(String status, String label) {
    Color color;
    switch (status) {
      case 'pending':
        color = AppColors.textSecond;
        break;
      case 'assigned':
        color = AppColors.blueLight;
        break;
      case 'on_the_way':
        color = AppColors.warning;
        break;
      case 'in_progress':
        color = AppColors.bluePrimary;
        break;
      case 'completed':
        color = AppColors.success;
        break;
      case 'cancelled':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textSecond;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.harmattan(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
