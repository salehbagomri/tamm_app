import 'package:tamm_app/core/constants/app_text_styles.dart';
import 'package:tamm_app/core/constants/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/widgets/tamm_button.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _setSeenWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcome', true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      context.colors.bluePrimary,
                      context.colors.blueLight,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.bluePrimary.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icons/tamm-logo.png',
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              AppSpacing.gapXl,
              Text(
                'خدمات التكييف والطاقة الشمسية',
                style: AppTextStyles.body(context.colors.textPrimary),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapSm2,
              Text(
                'تصفّح منتجاتنا وخدماتنا بكل سهولة',
                style: AppTextStyles.body(context.colors.textSecond),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              TammButton(
                label: 'تصفح التطبيق',
                onPressed: () async {
                  await _setSeenWelcome();
                  if (context.mounted) {
                    context.go('/customer/home');
                  }
                },
              ),
              AppSpacing.gapMd,
              TextButton(
                onPressed: () async {
                  await _setSeenWelcome();
                  if (context.mounted) {
                    context.push('/login');
                  }
                },
                child: Text(
                  'سجّل دخولك',
                  style: AppTextStyles.body(
                    context.colors.blueSky,
                  ).copyWith(fontWeight: AppTextStyles.bold),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
