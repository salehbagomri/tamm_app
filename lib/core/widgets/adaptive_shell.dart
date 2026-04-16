import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../utils/responsive.dart';

/// Navigation item data shared between bottom nav and sidebar
class NavItem {
  final IconData icon;
  final String label;
  final Widget? badge;

  const NavItem({required this.icon, required this.label, this.badge});
}

/// Adaptive shell that shows BottomNav on mobile and NavigationRail on tablet/desktop
class AdaptiveShell extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;

  const AdaptiveShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final useSide = Responsive.useSideNav(context);
    final isDesktop = Responsive.isDesktop(context);

    if (useSide) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              // Sidebar
              _TammSidebar(
                currentIndex: currentIndex,
                onTap: onTap,
                items: items,
                extended: isDesktop,
              ),
              // Divider
              Container(width: 1, color: AppColors.border),
              // Content
              Expanded(child: child),
            ],
          ),
        ),
      );
    }

    // Mobile: bottom nav
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: currentIndex,
          onTap: onTap,
          items: items
              .map((item) => BottomNavigationBarItem(
                    icon: item.badge != null
                        ? Badge(
                            isLabelVisible: true,
                            label: item.badge!,
                            backgroundColor: AppColors.error,
                            child: Icon(item.icon),
                          )
                        : Icon(item.icon),
                    label: item.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

/// Sidebar widget for tablet/desktop
class _TammSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;
  final bool extended;

  const _TammSidebar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
    required this.extended,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: extended ? 220 : 72,
      color: AppColors.bgSurface,
      child: Column(
        children: [
          // Logo area
          Container(
            height: 80,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: extended
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipOval(
                        child: Image.asset(
                          'assets/icons/tamm-logo.png',
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.ac_unit,
                            color: AppColors.bluePrimary,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'تمّ',
                        style: GoogleFonts.harmattan(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  )
                : ClipOval(
                    child: Image.asset(
                      'assets/icons/tamm-logo.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.ac_unit,
                        color: AppColors.bluePrimary,
                        size: 28,
                      ),
                    ),
                  ),
          ),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 8),

          // Nav items
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = index == currentIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(
                          horizontal: extended ? 16 : 0,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.bluePrimary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: extended
                            ? Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 22,
                                    color: isSelected
                                        ? AppColors.blueLight
                                        : AppColors.textSecond,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: GoogleFonts.harmattan(
                                        fontSize: 16,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppColors.blueLight
                                            : AppColors.textSecond,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (item.badge != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: item.badge!,
                                    ),
                                  ],
                                ],
                              )
                            : Center(
                                child: item.badge != null
                                    ? Badge(
                                        isLabelVisible: true,
                                        label: item.badge!,
                                        backgroundColor: AppColors.error,
                                        child: Icon(
                                          item.icon,
                                          size: 24,
                                          color: isSelected
                                              ? AppColors.blueLight
                                              : AppColors.textSecond,
                                        ),
                                      )
                                    : Icon(
                                        item.icon,
                                        size: 24,
                                        color: isSelected
                                            ? AppColors.blueLight
                                            : AppColors.textSecond,
                                      ),
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
