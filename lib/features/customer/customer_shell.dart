import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/tamm_bottom_nav.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/product_providers.dart';
import '../../shared/providers/service_providers.dart';
import '../../shared/providers/order_providers.dart';

class CustomerShell extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(roleStreamProvider, (prev, next) {
      final role = next.valueOrNull;
      if (role != null && role != 'customer') {
        if (role == 'manager') {
          context.go('/manager/dashboard');
        } else if (role == 'technician') {
          context.go('/technician/tasks');
        }
      }
    });

    return Scaffold(
      body: child,
      bottomNavigationBar: TammBottomNav(
        currentIndex: _currentIndex(context),
        onTap: (i) {
          switch (i) {
            case 0:
              ref.invalidate(userProfileProvider);
              ref.invalidate(featuredProductsProvider);
              context.go('/customer/home');
            case 1:
              ref.invalidate(productsProvider);
              context.go('/customer/store');
            case 2:
              ref.invalidate(serviceTypesProvider);
              context.go('/customer/services');
            case 3:
              ref.invalidate(userProfileProvider);
              ref.invalidate(myOrdersProvider);
              context.go('/customer/profile');
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: AppStrings.home,
          ),
          BottomNavigationBarItem(
            icon: Consumer(
              builder: (context, ref, child) {
                final count = ref.watch(cartCountProvider);
                
                return Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  backgroundColor: AppColors.error,
                  child: const Icon(Icons.store_rounded),
                );
              },
            ),
            label: AppStrings.store,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.build_rounded),
            label: AppStrings.services,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: AppStrings.profile,
          ),
        ],
      ),
    );
  }
}
