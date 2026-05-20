import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/tamm_colors.dart';
import '../../core/services/fcm_service.dart';
import '../../shared/repositories/auth_repository.dart';

class ManagerWebOnlyScreen extends ConsumerWidget {
  const ManagerWebOnlyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: context.colors.bluePrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.computer_outlined,
                  size: 64,
                  color: context.colors.bluePrimary,
                ),
              ),
              AppSpacing.gapXl,
              Text(
                'لوحة المدير على الويب',
                style: AppTextStyles.h2(context.colors.textPrimary),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapMd,
              Text(
                'هذا الحساب مخصص لإدارة المنصة عبر المتصفح.\nيرجى الدخول من خلال موقع تمّ الإلكتروني.',
                style: AppTextStyles.body(context.colors.textSecond),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapXl,
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await FcmService.unregisterToken();
                    await AuthRepository().signOut();
                    if (context.mounted) context.go('/customer/home');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colors.bluePrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppSpacing.radius,
                    ),
                  ),
                  child: Text(
                    'تسجيل الخروج',
                    style: AppTextStyles.body(Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
