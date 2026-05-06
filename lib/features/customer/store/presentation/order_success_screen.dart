import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_success_badge.dart';
import '../../../../shared/providers/order_providers.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class OrderSuccessScreen extends ConsumerWidget {
  final String orderId;
  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TammSuccessBadge(message: 'تمّ طلبك ✓'),
              const SizedBox(height: 16),
              Text(
                'تم استلام طلبك بنجاح وسيتم التواصل معك قريباً',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.colors.textSecond, fontSize: 16),
              ),
              const SizedBox(height: 24),
              orderAsync.when(
                data: (order) => Text(
                  'رقم الطلب: #${order.orderNumber}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => const SizedBox(),
              ),
              const SizedBox(height: 32),
              TammButton(
                label: 'تتبع الطلب',
                onPressed: () => context.push('/customer/order/$orderId'),
              ),
              const SizedBox(height: 12),
              TammButton(
                type: TammButtonType.secondary,
                label: 'الرئيسية',
                onPressed: () => context.go('/customer/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
