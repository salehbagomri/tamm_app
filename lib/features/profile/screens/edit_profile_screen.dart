import 'package:tamm_app/core/constants/app_text_styles.dart';
import 'package:tamm_app/core/constants/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_text_field.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/providers/auth_providers.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _loading = false;
  UserProfile? _currentProfile;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _nameCtrl.addListener(_checkForChanges);
    _phoneCtrl.addListener(_checkForChanges);
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final profile = await ref.read(authRepositoryProvider).getProfile();
    if (profile != null && mounted) {
      setState(() {
        _currentProfile = profile;
        _nameCtrl.text = profile.fullName;

        // Remove '+967' prefix for display in input field
        String phoneStr = profile.phone;
        if (phoneStr.startsWith('+967')) {
          phoneStr = phoneStr.substring(4);
        }
        _phoneCtrl.text = phoneStr;
        _loading = false;
        _hasChanges = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _checkForChanges() {
    if (_currentProfile == null) return;

    final currentPhoneRaw = _currentProfile!.phone.startsWith('+967')
        ? _currentProfile!.phone.substring(4)
        : _currentProfile!.phone;

    final newHasChanges =
        _nameCtrl.text.trim() != _currentProfile!.fullName ||
        _phoneCtrl.text.trim() != currentPhoneRaw;

    if (newHasChanges != _hasChanges) {
      setState(() {
        _hasChanges = newHasChanges;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      final currentUserId = repo.currentUserId;
      final phoneFormatted = '+967${_phoneCtrl.text.trim()}';

      // Check phone uniqueness if phone changed
      if (_phoneCtrl.text.trim() !=
          (_currentProfile?.phone.replaceFirst('+967', '') ?? '')) {
        final exists = await Supabase.instance.client
            .from('profiles')
            .select('id')
            .eq('phone', phoneFormatted)
            .neq('id', currentUserId ?? '')
            .maybeSingle();

        if (exists != null) {
          throw Exception('رقم الجوال مسجل بالفعل لحساب آخر');
        }
      }

      final updatedProfile = _currentProfile!.copyWith(
        fullName: _nameCtrl.text.trim(),
        phone: phoneFormatted,
      );

      await repo.updateProfile(updatedProfile);

      if (!mounted) return;
      ref.invalidate(userProfileProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم حفظ التعديلات بنجاح',
            style: AppTextStyles.body(context.colors.textPrimary),
          ),
          backgroundColor: context.colors.success,
        ),
      );

      context.pop();
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMsg,
              style: AppTextStyles.body(context.colors.textPrimary),
            ),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.bgPrimary,
        title: Text(
          'تعديل الحساب',
          style: AppTextStyles.h2(context.colors.textPrimary),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: _loading && _currentProfile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppSpacing.pagePadding,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: context.colors.bgSurface,
                        borderRadius: AppSpacing.radiusLg,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TammTextField(
                            label: 'الاسم الكامل',
                            controller: _nameCtrl,
                            prefix: const Icon(Icons.person_outline),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'الاسم الكامل مطلوب';
                              }
                              if (v.trim().length < 3) {
                                return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                              }
                              if (RegExp(
                                r'[0-9!@#%^&*(),.?":{}|<>]',
                              ).hasMatch(v)) {
                                return 'الاسم يجب أن يحتوي على أحرف فقط';
                              }
                              return null;
                            },
                          ),
                          AppSpacing.gapLg,
                          TammTextField(
                            label: 'رقم الجوال (بدون مفتاح الدولة)',
                            hint: '7XXXXXXXX',
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.number,
                            prefixText: '+967 ',
                            prefix: const Icon(Icons.phone_outlined),
                            maxLength: 9,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) {
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
                        ],
                      ),
                    ),
                    AppSpacing.gapXl,
                    if (_hasChanges)
                      TammButton(
                        label: 'حفظ التعديلات',
                        isLoading: _loading,
                        onPressed: _saveProfile,
                      )
                    else
                      const TammButton(
                        label: 'حفظ التعديلات',
                        type: TammButtonType.secondary,
                        onPressed: null,
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
