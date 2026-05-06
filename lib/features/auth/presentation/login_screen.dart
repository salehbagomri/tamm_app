import '../../../core/utils/platform_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/providers/auth_providers.dart';
import '../../../shared/providers/order_providers.dart';
import '../../../core/services/fcm_service.dart';

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
      if (msg.contains('canceled') || msg.contains('cancelled') || msg.toLowerCase().contains('sign_in_canceled')) {
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
      if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
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
          style: GoogleFonts.harmattan(fontSize: 16),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
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
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.bluePrimary.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/icons/tamm-logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                AppStrings.welcome,
                style: GoogleFonts.harmattan(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'سجّل دخولك للاستمتاع بكافة المميزات',
                style: GoogleFonts.harmattan(
                  fontSize: 16,
                  color: AppColors.textSecond,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
                            Image.network(
                              'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                              width: 24,
                              height: 24,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.g_mobiledata,
                                size: 28,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'الدخول بحساب Google',
                              style: GoogleFonts.harmattan(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.textFaint, thickness: 0.5)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('أو', style: GoogleFonts.harmattan(fontSize: 14, color: AppColors.textFaint)),
                  ),
                  const Expanded(child: Divider(color: AppColors.textFaint, thickness: 0.5)),
                ],
              ),
              const SizedBox(height: 20),
              
              // Email / Password
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'البريد الإلكتروني',
                  hintStyle: GoogleFonts.harmattan(color: AppColors.textFaint),
                  filled: true,
                  fillColor: AppColors.bgSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'كلمة المرور',
                  hintStyle: GoogleFonts.harmattan(color: AppColors.textFaint),
                  filled: true,
                  fillColor: AppColors.bgSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecond,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscure = !_obscure;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signInWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bluePrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'تسجيل الدخول',
                          style: GoogleFonts.harmattan(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: Text(
                      'ليس لديك حساب؟ أنشئ حساباً',
                      style: GoogleFonts.harmattan(fontSize: 14, color: AppColors.blueSky),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text(
                      'نسيت كلمة المرور؟',
                      style: GoogleFonts.harmattan(fontSize: 14, color: AppColors.textSecond),
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
