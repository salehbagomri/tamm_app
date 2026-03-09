import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../shared/providers/order_providers.dart';

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o.orderNumber,
                          style: GoogleFonts.harmattan(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          o.statusLabel,
                          style: GoogleFonts.harmattan(
                            fontSize: 14,
                            color: AppColors.textSecond,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${o.totalAmount.toInt()} ريال',
                      style: GoogleFonts.harmattan(
                        color: AppColors.blueSky,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const TammLoading(),
        error: (e, _) =>
            TammEmptyState(icon: Icons.error_outline, message: '$e'),
      ),
    );
  }
}
