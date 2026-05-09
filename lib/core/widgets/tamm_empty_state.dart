import 'package:flutter/material.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class TammEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const TammEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppSpacing.iconXxl,
              color: context.colors.textFaint,
            ),
            AppSpacing.gapMd,
            Text(
              message,
              style: AppTextStyles.cardTitle(context.colors.textSecond),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              AppSpacing.gapMd,
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: AppTextStyles.body(context.colors.blueLight),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
