import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/tamm_bottom_nav.dart';

class ManagerShell extends StatelessWidget {
  final Widget child;
  const ManagerShell({super.key, required this.child});
  int _idx(BuildContext c) {
    final loc = GoRouterState.of(c).matchedLocation;
    if (loc.startsWith('/manager/orders')) return 1;
    if (loc.startsWith('/manager/technicians')) return 2;
    if (loc.startsWith('/manager/products')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: TammBottomNav(
        currentIndex: _idx(context),
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/manager/dashboard');
            case 1:
              context.go('/manager/orders');
            case 2:
              context.go('/manager/technicians');
            case 3:
              context.go('/manager/products');
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
        ],
      ),
    );
  }
}
