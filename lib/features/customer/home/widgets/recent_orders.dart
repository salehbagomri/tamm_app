import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../shared/models/order.dart';
import '../../../../shared/providers/order_providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

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
              style: AppTextStyles.sectionTitle(context.colors.textPrimary),
            ),
            if (recentOrdersAsync.valueOrNull?.isNotEmpty ?? false)
              TextButton(
                onPressed: () => context.push('/customer/orders'),
                child: Text(
                  'كل الطلبات',
                  style: AppTextStyles.body(
                    context.colors.blueSky,
                  ).copyWith(fontWeight: AppTextStyles.semiBold),
                ),
              ),
          ],
        ),
        AppSpacing.gapSm2,
        recentOrdersAsync.when(
          data: (orders) {
            if (orders.isEmpty) return _buildEmptyState(context);

            return Column(
              children: orders.map((o) => _buildOrderTile(context, o)).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorStateWidget(
            message: e is AppException ? e.message : 'تعذّر تحميل الطلبات',
            onRetry: () => ref.invalidate(recentOrdersProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: context.colors.textFaint,
          ),
          AppSpacing.gapMd,
          Text(
            'لا توجد طلبات سابقة',
            style: AppTextStyles.cardTitle(context.colors.textPrimary),
          ),
          AppSpacing.gapSm,
          Text(
            'تصفح خدماتنا ومنتجاتنا لتبدأ طلبك الأول',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall(context.colors.textSecond),
          ),
          AppSpacing.gapMd,
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
    // Generate an icon/label based on type
    final isProduct =
        order.items.isNotEmpty && order.items.first.itemType == 'product';
    final icon = isProduct
        ? Icons.shopping_bag
        : order.orderType == 'quote_request'
        ? Icons.request_quote
        : Icons.build_circle;
    final title = _getOrderTypeLabel(order.orderType, isProduct);

    final dateFormat = DateFormat('yyyy/MM/dd');

    return InkWell(
      onTap: () => context.push('/customer/order/${order.id}'),
      borderRadius: AppSpacing.radiusSm,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: context.colors.bgSurface,
          borderRadius: AppSpacing.radiusSm,
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: AppSpacing.cardPaddingSm,
              decoration: BoxDecoration(
                color: context.colors.bluePrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: context.colors.blueSky),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.body(
                          context.colors.textPrimary,
                        ).copyWith(fontWeight: AppTextStyles.bold),
                      ),
                      _buildStatusLabel(
                        context,
                        order.status,
                        order.statusLabel,
                      ),
                    ],
                  ),
                  AppSpacing.gapXs,
                  Row(
                    children: [
                      Text(
                        '#${order.orderNumber}',
                        style: AppTextStyles.bodySmall(
                          context.colors.textSecond,
                        ).copyWith(fontWeight: AppTextStyles.bold),
                      ),
                      AppSpacing.hGapSm2,
                      Icon(
                        Icons.circle,
                        size: 4,
                        color: context.colors.textFaint,
                      ),
                      AppSpacing.hGapSm2,
                      Text(
                        dateFormat.format(order.createdAt),
                        style: AppTextStyles.bodySmall(
                          context.colors.textSecond,
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

  Widget _buildStatusLabel(BuildContext context, String status, String label) {
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

    return Text(
      label,
      style: AppTextStyles.bodySmall(
        color,
      ).copyWith(fontWeight: AppTextStyles.semiBold),
    );
  }

  String _getOrderTypeLabel(String orderType, bool isProduct) {
    if (isProduct) return 'طلب متجر';
    return switch (orderType) {
      'service' => 'طلب خدمة',
      'quote_request' => 'طلب عرض سعر',
      'product' => 'طلب منتج',
      'product_and_service' => 'منتج وخدمة',
      _ => 'طلب',
    };
  }
}
