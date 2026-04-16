import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
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
        NavItem(
          icon: Icons.task_alt_rounded,
          label: AppStrings.myTasks,
        ),
        NavItem(
          icon: Icons.person_rounded,
          label: AppStrings.profile,
        ),
      ],
      child: child,
    );
  }
}
