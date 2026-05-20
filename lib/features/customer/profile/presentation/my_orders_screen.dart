import '../../../../core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../shared/providers/order_providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: const TammAppBar(title: 'طلباتي'),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const TammEmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'لا توجد طلبات',
            );
          }
          return ListView.separated(
            padding: AppSpacing.pagePadding,
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final o = orders[i];
              return TammCard(
                onTap: () => context.push('/customer/order/${o.id}'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.orderTypeLabel,
                            style: AppTextStyles.body(
                              context.colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '#${o.orderNumber}',
                            style: AppTextStyles.body(
                              context.colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (o.orderType == 'quote_request' && o.quotePrice == null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.warning.withValues(alpha: 0.12),
                              borderRadius: AppSpacing.radiusFull,
                              border: Border.all(
                                color: context.colors.warning.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              'سعر حسب الطلب',
                              style: AppTextStyles.caption(context.colors.warning)
                                  .copyWith(fontWeight: AppTextStyles.semiBold),
                            ),
                          )
                        else
                          Text(
                            '${(o.orderType == 'quote_request' ? (o.quotePrice ?? 0) : o.totalAmount).toInt()} ر.س',
                            style: AppTextStyles.body(context.colors.textPrimary)
                                .copyWith(fontWeight: AppTextStyles.semiBold),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          o.statusLabel,
                          style: AppTextStyles.caption(
                            context.colors.textSecond,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const TammLoading(),
        error: (e, _) => ErrorStateWidget(
          message: e is AppException ? e.message : 'حدث خطأ في تحميل الطلبات',
          onRetry: () => ref.refresh(myOrdersProvider),
        ),
      ),
    );
  }
}
