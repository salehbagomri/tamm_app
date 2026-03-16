import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/tamm_bottom_nav.dart';
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

    return Scaffold(
      body: child,
      bottomNavigationBar: TammBottomNav(
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
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: AppStrings.dashboard,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: AppStrings.allOrders,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.engineering_rounded),
            label: AppStrings.manageTechs,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_rounded),
            label: AppStrings.manageProducts,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.handyman_rounded),
            label: 'الخدمات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.request_quote_rounded),
            label: 'عروض الأسعار',
          ),
        ],
      ),
    );
  }
}
