import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_text_field.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/providers/auth_providers.dart';

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
        
    final newHasChanges = _nameCtrl.text.trim() != _currentProfile!.fullName ||
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
      if (_phoneCtrl.text.trim() != (_currentProfile?.phone.replaceFirst('+967', '') ?? '')) {
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
          content: Text('تم حفظ التعديلات بنجاح', style: GoogleFonts.harmattan(fontSize: 16)),
          backgroundColor: AppColors.success,
        )
      );
      
      context.pop();
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg, style: GoogleFonts.harmattan(fontSize: 16)),
            backgroundColor: AppColors.error,
          )
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
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        title: Text(
          'تعديل الحساب',
          style: AppTextStyles.h2,
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
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
                        color: AppColors.bgSurface,
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
                              if (v == null || v.trim().isEmpty) return 'الاسم الكامل مطلوب';
                              if (v.trim().length < 3) return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                              if (RegExp(r'[0-9!@#%^&*(),.?":{}|<>]').hasMatch(v)) {
                                return 'الاسم يجب أن يحتوي على أحرف فقط';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TammTextField(
                            label: 'رقم الجوال (بدون مفتاح الدولة)',
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            prefixText: '+967 ',
                            prefix: const Icon(Icons.phone_outlined),
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'رقم الجوال مطلوب';
                              final digits = v.trim().replaceAll(RegExp(r'\D'), '');
                              if (!digits.startsWith('7')) return 'يجب أن يبدأ الرقم بـ 7';
                              if (digits.length < 9 || digits.length > 10) return 'رقم الجوال غير صحيح';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (_hasChanges)
                      TammButton(
                        label: 'حفظ التعديلات',
                        isLoading: _loading,
                        onPressed: _saveProfile,
                      )
                    else
                      TammButton(
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
