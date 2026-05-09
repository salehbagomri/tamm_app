import 'package:flutter/material.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class TammLoading extends StatelessWidget {
  final String? message;
  const TammLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: context.colors.bluePrimary),
          if (message != null) ...[
            AppSpacing.gapMd,
            Text(
              message!,
              style: AppTextStyles.body(context.colors.textSecond),
            ),
          ],
        ],
      ),
    );
  }
}
