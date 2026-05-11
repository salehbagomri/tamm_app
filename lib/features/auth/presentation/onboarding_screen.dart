import 'package:tamm_app/core/constants/app_text_styles.dart';
import 'package:tamm_app/core/constants/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/tamm_button.dart';
import '../../../core/widgets/tamm_text_field.dart';
import '../../../shared/providers/auth_providers.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

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
  String? _phoneError;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final currentUserId = repo.currentUserId;

      // التاكد من عدم تكرار الرقم
      final phoneFormatted = '+967${_phoneCtrl.text.trim()}';
      final exists = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('phone', phoneFormatted)
          .neq('id', currentUserId ?? '')
          .maybeSingle();

      if (exists != null) {
        setState(
          () => _phoneError = 'رقم الهاتف مستخدم بالفعل، يرجى إدخال رقم آخر',
        );
        return;
      }

      await repo.completeProfile(
        fullName: _nameCtrl.text.trim(),
        phone: phoneFormatted,
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
        final errorStr = e.toString();
        if (errorStr.contains('23505') ||
            errorStr.contains('unique') ||
            errorStr.contains('profiles_phone_unique')) {
          setState(
            () => _phoneError = 'رقم الهاتف مستخدم بالفعل، يرجى إدخال رقم آخر',
          );
        } else {
          final errorMsg = errorStr.replaceAll('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMsg,
                style: AppTextStyles.body(context.colors.textPrimary),
              ),
              backgroundColor: context.colors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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
        backgroundColor: context.colors.bgPrimary,
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
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            context.colors.bluePrimary,
                            context.colors.blueLight,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'تمّ',
                          style: AppTextStyles.body(context.colors.textPrimary),
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapLg,
                  Center(
                    child: Text(
                      'أكمل بياناتك',
                      style: AppTextStyles.body(context.colors.textPrimary),
                    ),
                  ),
                  AppSpacing.gapSm,
                  Center(
                    child: Text(
                      'نحتاج بعض المعلومات لإكمال حسابك',
                      style: AppTextStyles.body(context.colors.textSecond),
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
                      if (v.trim().length < 3) {
                        return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                      }
                      if (RegExp(r'[0-9!@#%^&*(),.?":{}|<>]').hasMatch(v)) {
                        return 'الاسم يجب أن يحتوي على أحرف فقط';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.gapMd,
                  TammTextField(
                    label: 'رقم الجوال',
                    hint: '7XXXXXXXX',
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.number,
                    prefixText: '+967 ',
                    maxLength: 9,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      if (_phoneError != null) {
                        setState(() => _phoneError = null);
                      }
                    },
                    validator: (v) {
                      if (_phoneError != null) return _phoneError;
                      if (v == null || v.trim().isEmpty) {
                        return 'رقم الجوال مطلوب';
                      }
                      final phoneRegex = RegExp(r'^7[0-9]{8}$');
                      if (!phoneRegex.hasMatch(v.trim())) {
                        return 'أدخل رقم هاتف يمني صحيح (7XXXXXXXX)';
                      }
                      return null;
                    },
                  ),
                  if (_phoneError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, right: 12.0),
                      child: Text(
                        _phoneError!,
                        style: AppTextStyles.body(context.colors.textPrimary),
                      ),
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
