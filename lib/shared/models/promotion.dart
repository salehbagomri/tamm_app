import 'package:flutter/material.dart';

class Promotion {
  final String id;
  final String title;
  final String subtitle;
  final String iconName;
  final String gradientStart;
  final String gradientEnd;
  final String destination;
  final int sortOrder;
  final bool isActive;

  const Promotion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconName,
    required this.gradientStart,
    required this.gradientEnd,
    required this.destination,
    required this.sortOrder,
    this.isActive = true,
  });

  factory Promotion.fromMap(Map<String, dynamic> map) {
    return Promotion(
      id: map['id'] as String,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String,
      iconName: map['icon_name'] as String,
      gradientStart: map['gradient_start'] as String,
      gradientEnd: map['gradient_end'] as String,
      destination: map['destination'] as String,
      sortOrder: map['sort_order'] as int,
      isActive: map['is_active'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'icon_name': iconName,
      'gradient_start': gradientStart,
      'gradient_end': gradientEnd,
      'destination': destination,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }

  static const Map<String, IconData> iconMap = {
    'handyman': Icons.handyman,
    'local_offer': Icons.local_offer,
    'solar_power': Icons.solar_power,
    'build_circle': Icons.build_circle,
    'ac_unit': Icons.ac_unit,
    'shopping_cart': Icons.shopping_cart,
    'flash_on': Icons.flash_on,
    'star': Icons.star,
    'campaign': Icons.campaign,
  };

  IconData get icon => iconMap[iconName] ?? Icons.campaign;

  List<Color> get gradientColors {
    return [
      Color(int.parse(gradientStart.replaceAll('#', '0xff'))),
      Color(int.parse(gradientEnd.replaceAll('#', '0xff'))),
    ];
  }
}
