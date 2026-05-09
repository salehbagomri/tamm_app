import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_notifier.dart';
import '../../core/theme/tamm_colors.dart';
import '../../core/widgets/adaptive_shell.dart';
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
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return; // Guest

      final role = next.valueOrNull;
      if (role != null && role != 'customer') {
        if (role == 'manager') {
          context.go('/manager/dashboard');
        } else if (role == 'technician') {
          context.go('/technician/tasks');
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
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    next.message,
                    style: GoogleFonts.harmattan(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            action: action,
          ),
        );
    });

    final cartCount = ref.watch(cartCountProvider);

    return AdaptiveShell(
      currentIndex: _currentIndex(context),
      onTap: (i) {
        final isGuest = ref.read(isGuestProvider);
        switch (i) {
          case 0:
            if (!isGuest) ref.invalidate(userProfileProvider);
            ref.invalidate(featuredProductsProvider);
            context.go('/customer/home');
          case 1:
            ref.invalidate(productsProvider);
            context.go('/customer/store');
          case 2:
            ref.invalidate(serviceTypesProvider);
            context.go('/customer/services');
          case 3:
            if (!isGuest) {
              ref.invalidate(userProfileProvider);
              ref.invalidate(myOrdersProvider);
            }
            context.go('/customer/profile');
        }
      },
      items: [
        const NavItem(icon: Icons.home_rounded, label: AppStrings.home),
        NavItem(
          icon: Icons.store_rounded,
          label: AppStrings.store,
          badge: cartCount > 0
              ? Text(
                  '$cartCount',
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                )
              : null,
        ),
        const NavItem(icon: Icons.build_rounded, label: AppStrings.services),
        const NavItem(icon: Icons.person_rounded, label: AppStrings.profile),
      ],
      child: child,
    );
  }
}
