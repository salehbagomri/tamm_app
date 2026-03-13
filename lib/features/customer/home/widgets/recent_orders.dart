import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../shared/models/order.dart';
import '../../../../shared/providers/order_providers.dart';

class RecentOrders extends ConsumerWidget {
  const RecentOrders({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentOrdersAsync = ref.watch(recentOrdersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'أحدث الطلبات',
              style: GoogleFonts.harmattan(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (recentOrdersAsync.valueOrNull?.isNotEmpty ?? false)
              TextButton(
                onPressed: () => context.go('/customer/orders'),
                child: Text(
                  'كل الطلبات',
                  style: GoogleFonts.harmattan(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blueSky,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        recentOrdersAsync.when(
          data: (orders) {
            if (orders.isEmpty) return _buildEmptyState(context);
            
            return Column(
              children: orders.map((o) => _buildOrderTile(context, o)).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppColors.textFaint,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد طلبات سابقة',
            style: GoogleFonts.harmattan(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تصفح خدماتنا ومنتجاتنا لتبدأ طلبك الأول',
            textAlign: TextAlign.center,
            style: GoogleFonts.harmattan(
              fontSize: 14,
              color: AppColors.textSecond,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 150,
            child: TammButton(
              label: 'ابدأ الآن',
              onPressed: () => context.go('/customer/services'),
              type: TammButtonType.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTile(BuildContext context, Order order) {
    // Generate an icon/label based on type or notes
    final isProduct = order.items.isNotEmpty && order.items.first.itemType == 'product';
    final icon = isProduct ? Icons.shopping_bag : Icons.build_circle;
    final title = isProduct ? 'طلب متجر' : order.orderType;
    
    final dateFormat = DateFormat('yyyy/MM/dd');
    
    return InkWell(
      onTap: () => context.push('/customer/order/${order.id}'),
      borderRadius: AppSpacing.radiusSm,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: AppSpacing.radiusSm,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bluePrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.blueSky),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.harmattan(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      _buildStatusLabel(order.status, order.statusLabel),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '#${order.orderNumber}',
                        style: GoogleFonts.harmattan(
                          fontSize: 14,
                          color: AppColors.textSecond,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.circle, size: 4, color: AppColors.textFaint),
                      const SizedBox(width: 12),
                      Text(
                        dateFormat.format(order.createdAt),
                        style: GoogleFonts.harmattan(
                          fontSize: 14,
                          color: AppColors.textSecond,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLabel(String status, String label) {
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

    return Text(
      label,
      style: GoogleFonts.harmattan(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}
