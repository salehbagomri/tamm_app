import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/tamm_bottom_nav.dart';

class CustomerShell extends StatelessWidget {
  final Widget child;
  const CustomerShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/customer/store')) return 1;
    if (loc.startsWith('/customer/services')) return 2;
    if (loc.startsWith('/customer/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: TammBottomNav(
        currentIndex: _currentIndex(context),
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/customer/home');
            case 1:
              context.go('/customer/store');
            case 2:
              context.go('/customer/services');
            case 3:
              context.go('/customer/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: AppStrings.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_rounded),
            label: AppStrings.store,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build_rounded),
            label: AppStrings.services,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: AppStrings.profile,
          ),
        ],
      ),
    );
  }
}
