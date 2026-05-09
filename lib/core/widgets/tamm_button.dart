import 'package:flutter/material.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

enum TammButtonType { primary, secondary, danger }

class TammButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final TammButtonType type;
  final IconData? icon;
  final double? width;

  const TammButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.type = TammButtonType.primary,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSecondary = type == TammButtonType.secondary;
    final bool isDanger = type == TammButtonType.danger;

    final Color textColor = isSecondary
        ? context.colors.bluePrimary
        : Colors.white;

    final child = isLoading
        ? SizedBox(
            width: AppSpacing.iconMd,
            height: AppSpacing.iconMd,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isSecondary ? context.colors.bluePrimary : Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppSpacing.iconSm, color: textColor),
                AppSpacing.hGapSm,
              ],
              Text(label, style: AppTextStyles.button(textColor)),
            ],
          );

    if (isSecondary) {
      return SizedBox(
        width: width ?? double.infinity,
        height: AppSpacing.buttonHeight,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: context.colors.bluePrimary),
            shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusLg),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: AppSpacing.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDanger
              ? context.colors.error
              : context.colors.bluePrimary,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusLg),
          elevation: 0,
        ),
        child: child,
      ),
    );
  }
}
