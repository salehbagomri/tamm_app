import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
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
          margin: const EdgeInsets.only(top: AppSpacing.lg),
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: context.colors.bgSurface,
            borderRadius: AppSpacing.radiusLg,
            border: Border.all(
              color: context.colors.bluePrimary.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: context.colors.bluePrimary.withValues(alpha: 0.1),
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
                      Icon(Icons.electric_bolt_outlined, color: context.colors.blueSky),
                      AppSpacing.hGapSm,
                      Text(
                        'طلب نشط',
                        style: AppTextStyles.body(
                          context.colors.blueSky,
                        ).copyWith(fontWeight: AppTextStyles.bold),
                      ),
                    ],
                  ),
                  _buildStatusBadge(context, order.status, order.statusLabel),
                ],
              ),
              AppSpacing.gapSm2,
              Text(
                'رقم الطلب: #${order.orderNumber}',
                style: AppTextStyles.cardTitle(context.colors.textPrimary),
              ),
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                AppSpacing.gapXs,
                Text(
                  order.notes!,
                  style: AppTextStyles.bodySmall(context.colors.textSecond),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (order.technicianName != null) ...[
                AppSpacing.gapSm,
                Row(
                  children: [
                    Icon(
                      Icons.engineering_outlined,
                      size: AppSpacing.iconSm,
                      color: context.colors.textSecond,
                    ),
                    AppSpacing.hGapXs,
                    Text(
                      'الفني: ${order.technicianName}',
                      style: AppTextStyles.bodySmall(context.colors.textSecond),
                    ),
                  ],
                ),
              ],
              AppSpacing.gapMd,
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/customer/order/${order.id}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.bluePrimary.withValues(
                      alpha: 0.1,
                    ),
                    foregroundColor: context.colors.blueSky,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppSpacing.radiusSm,
                    ),
                  ),
                  child: Text(
                    'تفاصيل الطلب',
                    style: AppTextStyles.button(context.colors.blueSky),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption(
          color,
        ).copyWith(fontWeight: AppTextStyles.semiBold),
      ),
    );
  }
}
