import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/tamm_app_bar.dart';
import '../../../core/widgets/tamm_button.dart';
import '../../../core/widgets/tamm_text_field.dart';
import '../../../shared/providers/auth_providers.dart';
import '../../../core/services/fcm_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.harmattan(fontSize: 16)),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    
    try {
      final repo = ref.read(authRepositoryProvider);
      
      // 1. Sign up with email
      final response = await repo.signUpWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      
      if (response.session == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إنشاء الحساب. يرجى التحقق من بريدك الإلكتروني لتفعيل حسابك.', style: GoogleFonts.harmattan(fontSize: 16)),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 5),
          ),
        );
        context.go('/login');
        return;
      }
      
      // 2. Complete profile
      final phoneFormatted = '+967${_phoneCtrl.text.trim()}';
      await repo.completeProfile(
        fullName: _nameCtrl.text.trim(),
        phone: phoneFormatted,
      );
      
      // 3. FCM Token
      await FcmService.registerToken();
      
      if (!mounted) return;
      context.go('/customer/home');
      
    } catch (e) {
      debugPrint('Registration error: $e');
      final msg = e.toString().toLowerCase();
      if (msg.contains('already registered') || msg.contains('user_already_exists')) {
        _showError('البريد الإلكتروني مسجل مسبقاً');
      } else {
        _showError('فشل إنشاء الحساب، تأكد من صحة البيانات.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: const TammAppBar(title: 'إنشاء حساب'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً بك في تمّ!',
                  style: GoogleFonts.harmattan(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'قم بإنشاء حسابك لتتمكن من طلب الخدمات والمنتجات بكل سهولة',
                  style: GoogleFonts.harmattan(
                    fontSize: 16,
                    color: AppColors.textSecond,
                  ),
                ),
                const SizedBox(height: 32),
                
                TammTextField(
                  label: 'الاسم الكامل',
                  hint: 'مثال: صالح عمر',
                  controller: _nameCtrl,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'الاسم الكامل مطلوب';
                    if (v.trim().length < 3) return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TammTextField(
                  label: 'البريد الإلكتروني',
                  hint: 'example@domain.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'البريد الإلكتروني مطلوب';
                    if (!v.contains('@')) return 'صيغة البريد الإلكتروني غير صحيحة';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TammTextField(
                  label: 'رقم الجوال',
                  hint: '7XXXXXXXX',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  prefixText: '+967 ',
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'رقم الجوال مطلوب';
                    final digits = v.trim().replaceAll(RegExp(r'\D'), '');
                    if (!digits.startsWith('7')) return 'يجب أن يبدأ الرقم بـ 7';
                    if (digits.length < 9 || digits.length > 10) return 'رقم الجوال غير صحيح';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TammTextField(
                  label: 'كلمة المرور',
                  hint: '••••••••',
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  suffix: IconButton(
                    icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecond),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
                    if (v.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TammTextField(
                  label: 'تأكيد كلمة المرور',
                  hint: '••••••••',
                  controller: _confirmPassCtrl,
                  obscureText: _obscureConfirmPass,
                  suffix: IconButton(
                    icon: Icon(_obscureConfirmPass ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecond),
                    onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'يرجى تأكيد كلمة المرور';
                    if (v != _passCtrl.text) return 'كلمات المرور غير متطابقة';
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                
                TammButton(
                  label: 'إنشاء حساب',
                  isLoading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 24),
                
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'لديك حساب بالفعل؟ سجّل دخولك',
                      style: GoogleFonts.harmattan(fontSize: 16, color: AppColors.blueSky),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
