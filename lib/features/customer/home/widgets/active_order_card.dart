import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/providers/order_providers.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

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
            color: context.colors.bgSurface,
            borderRadius: AppSpacing.radiusLg,
            border: Border.all(
              color: context.colors.bluePrimary.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: context.colors.bluePrimary.withOpacity(0.1),
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
                      Icon(Icons.electric_bolt, color: context.colors.blueSky),
                      const SizedBox(width: 8),
                      Text(
                        'طلب نشط',
                        style: GoogleFonts.harmattan(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.colors.blueSky,
                        ),
                      ),
                    ],
                  ),
                  _buildStatusBadge(context, order.status, order.statusLabel),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'رقم الطلب: #${order.orderNumber}',
                style: GoogleFonts.harmattan(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
              ),
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  order.notes!,
                  style: GoogleFonts.harmattan(
                    fontSize: 14,
                    color: context.colors.textSecond,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (order.technicianName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.engineering,
                      size: 16,
                      color: context.colors.textSecond,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'الفني: ${order.technicianName}',
                      style: GoogleFonts.harmattan(
                        fontSize: 14,
                        color: context.colors.textSecond,
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
                    backgroundColor: context.colors.bluePrimary.withOpacity(
                      0.1,
                    ),
                    foregroundColor: context.colors.blueSky,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
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

  Widget _buildStatusBadge(BuildContext context, String status, String label) {
    Color color;
    switch (status) {
      case 'pending':
        color = context.colors.textSecond;
        break;
      case 'assigned':
        color = context.colors.blueLight;
        break;
      case 'on_the_way':
        color = context.colors.warning;
        break;
      case 'in_progress':
        color = context.colors.bluePrimary;
        break;
      case 'completed':
        color = context.colors.success;
        break;
      case 'cancelled':
        color = context.colors.error;
        break;
      default:
        color = context.colors.textSecond;
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
