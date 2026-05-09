import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_success_badge.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class ServiceSuccessScreen extends StatelessWidget {
  const ServiceSuccessScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TammSuccessBadge(message: 'تمّ الحجز ✓'),
              AppSpacing.gapMd,
              Text(
                'سيتم التواصل معك لتأكيد الموعد',
                style: TextStyle(
                  color: context.colors.textSecond,
                  fontSize: 16,
                ),
              ),
              AppSpacing.gapXl,
              TammButton(
                label: 'الرئيسية',
                onPressed: () => context.go('/customer/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
