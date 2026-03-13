import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

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

    Color textColor;
    if (isSecondary) {
      textColor = AppColors.bluePrimary;
    } else if (isDanger) {
      textColor = Colors.white;
    } else {
      textColor = AppColors.bgPrimary; // Primary button text color (usually dark)
    }
    
    // In original code, AppTextStyles.button was used for primary, and copyWith(color) for outlined.
    // Assuming primary button is dark text on white background depending on theme, or white on blue.
    // Let's stick to the original logic for primary, and add danger.
    final textStyle = isSecondary || isDanger
        ? AppTextStyles.button.copyWith(color: textColor)
        : AppTextStyles.button; // Uses default from style

    final child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isSecondary ? AppColors.bluePrimary : Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: textColor),
                const SizedBox(width: 8),
              ],
              Text(label, style: textStyle),
            ],
          );

    if (isSecondary) {
      return SizedBox(
        width: width ?? double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.bluePrimary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDanger ? AppColors.error : AppColors.bluePrimary,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: child,
      ),
    );
  }
}
