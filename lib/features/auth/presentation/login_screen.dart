import 'package:tamm_app/core/constants/app_text_styles.dart';
import 'package:tamm_app/core/constants/app_spacing.dart';
import '../../../core/utils/platform_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/providers/auth_providers.dart';
import '../../../shared/providers/order_providers.dart';
import '../../../core/services/fcm_service.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithGoogle();

      if (kIsWeb) return;

      final profile = await repo.getProfile();
      if (!mounted) return;

      await FcmService.registerToken();
      await ref.read(cartProvider.notifier).mergeGuestCart();
      if (!mounted) return;

      if (profile == null || !profile.isComplete) {
        context.go('/onboarding');
      } else {
        switch (profile.role) {
          case 'manager':
            context.go('/manager/dashboard');
          case 'technician':
            context.go('/technician/tasks');
          default:
            context.go('/customer/home');
        }
      }
    } catch (e) {
      if (PlatformUtils.isNetworkError(e)) {
        _showError('تحقق من اتصالك بالإنترنت');
        return;
      }
      final msg = e.toString();
      if (msg.contains('canceled') ||
          msg.contains('cancelled') ||
          msg.toLowerCase().contains('sign_in_canceled')) {
        return;
      }
      debugPrint('Login error: $msg');
      if (msg.contains('AuthException')) {
        _showError('حدث خطأ في الخادم، حاول مجدداً');
      } else {
        _showError('حدث خطأ، حاول مجدداً');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithEmail() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      _showError('يرجى إدخال البريد الإلكتروني وكلمة المرور');
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithEmail(email: email, password: password);

      final profile = await repo.getProfile();
      if (!mounted) return;

      await FcmService.registerToken();
      await ref.read(cartProvider.notifier).mergeGuestCart();
      if (!mounted) return;

      if (profile == null || !profile.isComplete) {
        context.go('/onboarding');
      } else {
        switch (profile.role) {
          case 'manager':
            context.go('/manager/dashboard');
          case 'technician':
            context.go('/technician/tasks');
          default:
            context.go('/customer/home');
        }
      }
    } catch (e) {
      debugPrint('Email login error: $e');
      final msg = e.toString().toLowerCase();
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid_credentials')) {
        _showError('البريد الإلكتروني أو كلمة المرور غير صحيحة');
      } else {
        _showError('فشل تسجيل الدخول، حاول مجدداً');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.body(context.colors.textPrimary),
        ),
        backgroundColor: context.colors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: context.canPop()
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: context.colors.textPrimary),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
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
                AppStrings.welcome,
                style: AppTextStyles.body(context.colors.textPrimary),
              ),
              AppSpacing.gapSm,
              Text(
                'سجّل دخولك للاستمتاع بكافة المميزات',
                style: AppTextStyles.body(context.colors.textSecond),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapXl,

              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppSpacing.radiusLg,
                    ),
                    elevation: 2,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/google_logo.svg',
                              width: 24,
                              height: 24,
                            ),
                            AppSpacing.hGapSm2,
                            Text(
                              'الدخول بحساب Google',
                              style: AppTextStyles.cardTitle(Colors.black87),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: context.colors.textFaint,
                      thickness: 0.5,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'أو',
                      style: AppTextStyles.bodySmall(context.colors.textFaint),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: context.colors.textFaint,
                      thickness: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Email / Password
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: context.colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'البريد الإلكتروني',
                  hintStyle: AppTextStyles.body(context.colors.textFaint),
                  filled: true,
                  fillColor: context.colors.bgSurface,
                  border: const OutlineInputBorder(
                    borderRadius: AppSpacing.radius,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              AppSpacing.gapSm2,
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                style: TextStyle(color: context.colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'كلمة المرور',
                  hintStyle: AppTextStyles.body(context.colors.textFaint),
                  filled: true,
                  fillColor: context.colors.bgSurface,
                  border: const OutlineInputBorder(
                    borderRadius: AppSpacing.radius,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: context.colors.textSecond,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscure = !_obscure;
                      });
                    },
                  ),
                ),
              ),
              AppSpacing.gapLg,
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signInWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.bluePrimary,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppSpacing.radius,
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'تسجيل الدخول',
                          style: AppTextStyles.body(context.colors.textPrimary),
                        ),
                ),
              ),
              AppSpacing.gapSm2,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: Text(
                      'ليس لديك حساب؟ أنشئ حساباً',
                      style: AppTextStyles.bodySmall(context.colors.blueSky),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text(
                      'نسيت كلمة المرور؟',
                      style: AppTextStyles.bodySmall(context.colors.textSecond),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
