import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/providers/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final repo = ref.read(authRepositoryProvider);
    if (!repo.isLoggedIn) {
      context.go('/login');
      return;
    }

    final profile = await repo.getProfile();
    if (profile == null || !profile.isComplete) {
      context.go('/onboarding');
      return;
    }

    switch (profile.role) {
      case 'manager':
        context.go('/manager/dashboard');
      case 'technician':
        context.go('/technician/tasks');
      default:
        context.go('/customer/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                child: Text(
                  'تمّ',
                  style: GoogleFonts.harmattan(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'خدمات التكييف والطاقة الشمسية',
              style: GoogleFonts.harmattan(
                fontSize: 18,
                color: AppColors.textSecond,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: AppColors.bluePrimary,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
