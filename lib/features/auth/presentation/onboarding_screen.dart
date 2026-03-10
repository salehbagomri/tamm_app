import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/tamm_button.dart';
import '../../../core/widgets/tamm_text_field.dart';
import '../../../shared/providers/auth_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.completeProfile(
        fullName: _nameCtrl.text.trim(),
        phone: '+967${_phoneCtrl.text.trim()}',
      );

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
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
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
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'أكمل بياناتك',
                      style: GoogleFonts.harmattan(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'نحتاج بعض المعلومات لإكمال حسابك',
                      style: GoogleFonts.harmattan(
                        fontSize: 16,
                        color: AppColors.textSecond,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  TammTextField(
                    label: 'الاسم الكامل',
                    hint: 'مثال: صالح عمر',
                    controller: _nameCtrl,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'الاسم الكامل مطلوب';
                      }
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
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'رقم الجوال مطلوب';
                      }
                      if (v.trim().length < 9) {
                        return 'رقم الجوال غير صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  TammButton(
                    label: 'ابدأ الآن',
                    isLoading: _loading,
                    onPressed: _submit,
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
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }
}
