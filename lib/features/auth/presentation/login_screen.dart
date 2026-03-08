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
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final phone = '+967${_phoneController.text.trim()}';
      await ref.read(authRepositoryProvider).sendOtp(phone);
      if (mounted) context.push('/otp', extra: phone);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: ${e.toString()}')));
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                TammTextField(
                  label: AppStrings.enterPhone,
                  hint: AppStrings.phoneHint,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefix: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '967+',
                      style: GoogleFonts.harmattan(
                        fontSize: 16,
                        color: AppColors.textSecond,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'أدخل رقم الجوال';
                    if (v.length < 9) return 'رقم الجوال غير صحيح';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                TammButton(
                  label: AppStrings.loginBtn,
                  isLoading: _loading,
                  onPressed: _sendOtp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
