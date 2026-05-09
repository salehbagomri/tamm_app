import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_notifier.dart';
import '../../core/theme/tamm_colors.dart';
import '../../core/widgets/adaptive_shell.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/technician_providers.dart';

class TechnicianShell extends ConsumerWidget {
  final Widget child;
  const TechnicianShell({super.key, required this.child});
  int _idx(BuildContext c) {
    final loc = GoRouterState.of(c).matchedLocation;
    if (loc.startsWith('/technician/profile')) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(roleStreamProvider, (prev, next) {
      final role = next.valueOrNull;
      if (role != null && role != 'technician') {
        if (role == 'manager') {
          context.go('/manager/dashboard');
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

    return AdaptiveShell(
      currentIndex: _idx(context),
      onTap: (i) {
        switch (i) {
          case 0:
            ref.invalidate(myAssignmentsProvider);
            context.go('/technician/tasks');
          case 1:
            ref.invalidate(userProfileProvider);
            context.go('/technician/profile');
        }
      },
      items: const [
        NavItem(icon: Icons.task_alt_rounded, label: AppStrings.myTasks),
        NavItem(icon: Icons.person_rounded, label: AppStrings.profile),
      ],
      child: child,
    );
  }
}
