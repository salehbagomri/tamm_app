import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/providers/auth_providers.dart';
import '../../../core/services/fcm_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_fadeController);

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    try {
      final repo = ref.read(authRepositoryProvider);
      if (!repo.isLoggedIn) {
        _navigate('/login');
        return;
      }

      final profile = await repo.getProfile();
      if (profile == null || !profile.isComplete) {
        _navigate('/onboarding');
        return;
      }

      // تسجيل FCM Token بعد التحقق من الجلسة
      await FcmService.registerToken();

      switch (profile.role) {
        case 'manager':
          _navigate('/manager/dashboard');
        case 'technician':
          _navigate('/technician/tasks');
        default:
          _navigate('/customer/home');
      }
    } catch (e) {
      // In case of error (e.g. network), gracefully fallback to login
      debugPrint('Splash redirect error: $e');
      _navigate('/login');
    }
  }

  void _navigate(String route) {
    if (!mounted) return;
    _fadeController.forward().then((_) {
      if (mounted) context.go(route);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
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
              const SizedBox(height: 24),
              Text(
                'خدمات التكييف والطاقة الشمسية',
                style: GoogleFonts.harmattan(
                  fontSize: 18,
                  color: AppColors.textSecond,
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return AnimatedBuilder(
                    animation: _dotsController,
                    builder: (context, child) {
                      final double delay = index * 0.2;
                      final double value = (_dotsController.value - delay) % 1.0;
                      final double opacity = value < 0 ? 0 : (value > 0.5 ? 2 * (1 - value) : 2 * value);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Opacity(
                          opacity: opacity.clamp(0.2, 1.0),
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.bluePrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
