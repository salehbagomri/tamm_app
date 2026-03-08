import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/tamm_button.dart';
import '../../../core/widgets/tamm_text_field.dart';
import '../../../shared/providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _isSignUp = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isSignUp) {
        await repo.signUp(
          email,
          password,
          _nameController.text.trim(),
          _phoneController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إنشاء الحساب بنجاح! سجل دخولك الآن'),
            ),
          );
          setState(() => _isSignUp = false);
        }
      } else {
        await repo.signIn(email, password);
        final profile = await repo.getProfile();
        if (!mounted) return;

        switch (profile?.role) {
          case 'manager':
            context.go('/manager/dashboard');
          case 'technician':
            context.go('/technician/tasks');
          default:
            context.go('/customer/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.bluePrimary, AppColors.blueLight],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'تمّ',
                        style: GoogleFonts.harmattan(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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
                    AppStrings.welcomeSub,
                    style: GoogleFonts.harmattan(
                      fontSize: 16,
                      color: AppColors.textSecond,
                    ),
                  ),
                  const SizedBox(height: 48),

                  if (_isSignUp) ...[
                    TammTextField(
                      label: 'الاسم الكامل',
                      hint: 'مثال: صالح عمر',
                      controller: _nameController,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'أدخل الاسم الكامل';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TammTextField(
                      label: 'رقم الجوال',
                      hint: 'مثال: 777123456',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'أدخل رقم الجوال';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  TammTextField(
                    label: 'البريد الإلكتروني',
                    hint: 'example@email.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'أدخل البريد الإلكتروني';
                      if (!v.contains('@')) return 'بريد إلكتروني غير صحيح';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TammTextField(
                    label: 'كلمة المرور',
                    hint: '••••••••',
                    controller: _passwordController,
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
                      if (v.length < 6)
                        return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  TammButton(
                    label: _isSignUp ? 'إنشاء حساب' : 'دخول',
                    isLoading: _loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp
                          ? 'لديك حساب؟ سجل دخول'
                          : 'ليس لديك حساب؟ أنشئ حساب',
                      style: GoogleFonts.harmattan(
                        fontSize: 16,
                        color: AppColors.blueLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
