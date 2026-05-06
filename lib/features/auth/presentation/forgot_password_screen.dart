import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/tamm_app_bar.dart';
import '../../../core/widgets/tamm_button.dart';
import '../../../core/widgets/tamm_text_field.dart';
import '../../../shared/providers/auth_providers.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _isSent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.harmattan(fontSize: 16)),
        backgroundColor: context.colors.error,
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('يرجى إدخال بريد إلكتروني صحيح');
      return;
    }
    
    setState(() => _loading = true);
    
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.resetPassword(email);
      if (!mounted) return;
      setState(() => _isSent = true);
    } catch (e) {
      debugPrint('Reset password error: $e');
      _showError('حدث خطأ أثناء إرسال الرابط، تحقق من البريد الإلكتروني.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: const TammAppBar(title: 'استعادة كلمة المرور'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: _isSent
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mark_email_read_outlined, size: 80, color: context.colors.success),
                    const SizedBox(height: 24),
                    Text(
                      'تم إرسال رابط استعادة كلمة المرور بنجاح!',
                      style: GoogleFonts.harmattan(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'يرجى التحقق من بريدك الإلكتروني (بما في ذلك صندوق المهملات) واتباع الرابط لتعيين كلمة مرور جديدة.',
                      style: GoogleFonts.harmattan(
                        fontSize: 16,
                        color: context.colors.textSecond,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    TammButton(
                      label: 'العودة لتسجيل الدخول',
                      onPressed: () => context.go('/login'),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نسيت كلمة المرور؟',
                      style: GoogleFonts.harmattan(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'أدخل بريدك الإلكتروني المسجل وسنرسل لك رابطاً لإعادة تعيين كلمة المرور.',
                      style: GoogleFonts.harmattan(
                        fontSize: 16,
                        color: context.colors.textSecond,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TammTextField(
                      label: 'البريد الإلكتروني',
                      hint: 'example@domain.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 32),
                    TammButton(
                      label: 'إرسال الرابط',
                      isLoading: _loading,
                      onPressed: _submit,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
