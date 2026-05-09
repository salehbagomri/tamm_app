import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_notifier.dart';
import '../../core/theme/tamm_colors.dart';
import '../../core/widgets/adaptive_shell.dart';
import '../../shared/providers/manager_providers.dart';
import '../../shared/providers/order_providers.dart';
import '../../shared/providers/auth_providers.dart';

class ManagerShell extends ConsumerWidget {
  final Widget child;
  const ManagerShell({super.key, required this.child});
  int _idx(BuildContext c) {
    final loc = GoRouterState.of(c).matchedLocation;
    if (loc.startsWith('/manager/orders')) return 1;
    if (loc.startsWith('/manager/technicians')) return 2;
    if (loc.startsWith('/manager/products')) return 3;
    if (loc.startsWith('/manager/services')) return 4;
    if (loc.startsWith('/manager/quotes')) return 5;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(roleStreamProvider, (prev, next) {
      final role = next.valueOrNull;
      if (role != null && role != 'manager') {
        if (role == 'technician') {
          context.go('/technician/tasks');
        } else if (role == 'customer') {
          context.go('/customer/home');
        }
      }
    });

    ref.listen(errorProvider, (prev, next) {
      if (next == null) return;
      if (!context.mounted) return;

      // مسح الخطأ أولاً لتجنب race condition مع auto-clear Timer
      ref.read(errorProvider.notifier).clear();

      SnackBarAction? action;
      if (next.action == ErrorAction.relogin) {
        action = SnackBarAction(
          textColor: Colors.white,
          label: 'تسجيل الدخول',
          onPressed: () => context.go('/login'),
        );
      } else if (next.action == ErrorAction.retry) {
        action = SnackBarAction(
          textColor: Colors.white,
          label: 'إعادة',
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        );
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 4),
            backgroundColor: context.colors.error,
            behavior: SnackBarBehavior.floating,
            margin: AppSpacing.cardPaddingSm,
            shape: const RoundedRectangleBorder(
              borderRadius: AppSpacing.radius,
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: AppSpacing.iconSm,
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: Text(
                    next.message,
                    style: AppTextStyles.body(Colors.white),
                  ),
                ),
              ],
            ),
            action: action,
          ),
        );
    });

    return AdaptiveShell(
      currentIndex: _idx(context),
      onTap: (i) {
        switch (i) {
          case 0:
            ref.invalidate(dashboardStatsProvider);
            context.go('/manager/dashboard');
          case 1:
            ref.invalidate(allOrdersProvider);
            context.go('/manager/orders');
          case 2:
            ref.invalidate(techniciansProvider);
            context.go('/manager/technicians');
          case 3:
            context.go('/manager/products');
          case 4:
            ref.invalidate(managerServicesProvider);
            context.go('/manager/services');
          case 5:
            context.go('/manager/quotes');
        }
      },
      items: const [
        NavItem(icon: Icons.dashboard_rounded, label: AppStrings.dashboard),
        NavItem(icon: Icons.receipt_long_rounded, label: AppStrings.allOrders),
        NavItem(icon: Icons.engineering_rounded, label: AppStrings.manageTechs),
        NavItem(
          icon: Icons.inventory_rounded,
          label: AppStrings.manageProducts,
        ),
        NavItem(icon: Icons.handyman_rounded, label: 'الخدمات'),
        NavItem(icon: Icons.request_quote_rounded, label: 'عروض الأسعار'),
      ],
      child: child,
    );
  }
}
