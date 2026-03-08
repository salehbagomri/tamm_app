import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_success_badge.dart';

class ServiceSuccessScreen extends StatelessWidget {
  const ServiceSuccessScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TammSuccessBadge(message: 'تمّ الحجز ✓'),
              const SizedBox(height: 16),
              const Text(
                'سيتم التواصل معك لتأكيد الموعد',
                style: TextStyle(color: AppColors.textSecond, fontSize: 16),
              ),
              const SizedBox(height: 32),
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
