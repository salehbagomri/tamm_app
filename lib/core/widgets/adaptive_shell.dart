import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../utils/responsive.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

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
        backgroundColor: context.colors.bgPrimary,
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
              Container(width: 1, color: context.colors.border),
              // Content
              Expanded(child: child),
            ],
          ),
        ),
      );
    }

    // Mobile: bottom nav
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.colors.border)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: currentIndex,
          onTap: onTap,
          items: items
              .map(
                (item) => BottomNavigationBarItem(
                  icon: item.badge != null
                      ? Badge(
                          isLabelVisible: true,
                          label: item.badge!,
                          backgroundColor: context.colors.error,
                          child: Icon(item.icon),
                        )
                      : Icon(item.icon),
                  label: item.label,
                ),
              )
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
      color: context.colors.bgSurface,
      child: Column(
        children: [
          // Logo area
          Container(
            height: 80,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm2),
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
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.ac_unit,
                            color: context.colors.bluePrimary,
                            size: 28,
                          ),
                        ),
                      ),
                      AppSpacing.hGapSm2,
                      Text(
                        'تمّ',
                        style: GoogleFonts.alexandria(
                          fontSize: AppTextStyles.fontSizeXl2,
                          fontWeight: AppTextStyles.bold,
                          color: context.colors.textPrimary,
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
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.ac_unit,
                        color: context.colors.bluePrimary,
                        size: 28,
                      ),
                    ),
                  ),
          ),
          Divider(color: context.colors.border, height: 1),
          AppSpacing.gapSm,

          // Nav items
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = index == currentIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: AppSpacing.radius,
                    child: InkWell(
                      borderRadius: AppSpacing.radius,
                      onTap: () => onTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(
                          horizontal: extended
                              ? AppSpacing.md
                              : AppSpacing.none,
                          vertical: AppSpacing.sm2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.colors.bluePrimary.withValues(
                                  alpha: 0.15,
                                )
                              : Colors.transparent,
                          borderRadius: AppSpacing.radius,
                        ),
                        child: extended
                            ? Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 22,
                                    color: isSelected
                                        ? context.colors.blueLight
                                        : context.colors.textSecond,
                                  ),
                                  AppSpacing.hGapSm2,
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: GoogleFonts.alexandria(
                                        fontSize: AppTextStyles.fontSizeBase,
                                        fontWeight: isSelected
                                            ? AppTextStyles.bold
                                            : AppTextStyles.medium,
                                        color: isSelected
                                            ? context.colors.blueLight
                                            : context.colors.textSecond,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (item.badge != null) ...[
                                    AppSpacing.hGapSm,
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.colors.error,
                                        borderRadius: BorderRadius.circular(10),
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
                                        backgroundColor: context.colors.error,
                                        child: Icon(
                                          item.icon,
                                          size: AppSpacing.iconMd,
                                          color: isSelected
                                              ? context.colors.blueLight
                                              : context.colors.textSecond,
                                        ),
                                      )
                                    : Icon(
                                        item.icon,
                                        size: AppSpacing.iconMd,
                                        color: isSelected
                                            ? context.colors.blueLight
                                            : context.colors.textSecond,
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
