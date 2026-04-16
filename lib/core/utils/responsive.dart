import 'package:flutter/material.dart';

/// Responsive breakpoints and utilities for adaptive layouts
class Responsive {
  Responsive._();

  // Breakpoints
  static const double mobileMax = 768;
  static const double tabletMax = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileMax;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileMax &&
      MediaQuery.of(context).size.width < tabletMax;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletMax;

  /// Whether to show sidebar instead of bottom nav
  static bool useSideNav(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileMax;

  /// Max content width based on screen size
  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= tabletMax) return 1100;
    if (width >= mobileMax) return 800;
    return double.infinity;
  }

  /// Grid cross-axis count for product/service cards
  static int gridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= tabletMax) return 4;
    if (width >= mobileMax) return 3;
    return 2;
  }
}
