import 'package:flutter/material.dart';
import '../utils/responsive.dart';

/// Wraps content with a max-width constraint on larger screens
/// to prevent content from stretching to full width
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? Responsive.contentMaxWidth(context);

    if (effectiveMaxWidth == double.infinity) {
      return child;
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}
