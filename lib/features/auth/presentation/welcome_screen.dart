import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/tamm_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _setSeenWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcome', true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
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
                  gradient: const LinearGradient(
                    colors: [AppColors.bluePrimary, AppColors.blueLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.bluePrimary.withValues(alpha: 0.4),
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
              const SizedBox(height: 32),
              Text(
                'خدمات التكييف والطاقة الشمسية',
                style: GoogleFonts.harmattan(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'تصفّح منتجاتنا وخدماتنا بكل سهولة',
                style: GoogleFonts.harmattan(
                  fontSize: 16,
                  color: AppColors.textSecond,
                ),
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
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await _setSeenWelcome();
                  if (context.mounted) {
                    context.push('/login');
                  }
                },
                child: Text(
                  'سجّل دخولك',
                  style: GoogleFonts.harmattan(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blueSky,
                  ),
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
