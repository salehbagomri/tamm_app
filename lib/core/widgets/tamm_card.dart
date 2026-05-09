import 'package:flutter/material.dart';
import '../constants/app_spacing.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class TammCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const TammCard({super.key, required this.child, this.onTap, this.padding});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: context.colors.bgSurface,
          borderRadius: AppSpacing.radius,
          border: Border.all(color: context.colors.border),
        ),
        child: child,
      ),
    );
  }
}
