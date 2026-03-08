import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const radius = BorderRadius.all(Radius.circular(12));
  static const radiusSm = BorderRadius.all(Radius.circular(8));
  static const radiusLg = BorderRadius.all(Radius.circular(16));
  static const radiusFull = BorderRadius.all(Radius.circular(100));

  static const pagePadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  static const cardPadding = EdgeInsets.all(16);
}
