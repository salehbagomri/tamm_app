import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/tamm_bottom_nav.dart';

class TechnicianShell extends StatelessWidget {
  final Widget child;
  const TechnicianShell({super.key, required this.child});
  int _idx(BuildContext c) {
    final loc = GoRouterState.of(c).matchedLocation;
    if (loc.startsWith('/technician/profile')) return 1;
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
              context.go('/technician/tasks');
            case 1:
              context.go('/technician/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt_rounded),
            label: AppStrings.myTasks,
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
