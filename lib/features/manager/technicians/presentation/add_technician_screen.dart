import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_text_field.dart';
import '../../../../shared/providers/manager_providers.dart';

class AddTechnicianScreen extends ConsumerStatefulWidget {
  const AddTechnicianScreen({super.key});
  @override
  ConsumerState<AddTechnicianScreen> createState() =>
      _AddTechnicianScreenState();
}

class _AddTechnicianScreenState extends ConsumerState<AddTechnicianScreen> {
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSearching = false;
  Map<String, dynamic>? _foundProfile;
  String? _errorMsg;

  String _specialization = 'مكيفات';
  bool _isPromoting = false;

  Future<void> _searchByPhone() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isSearching = true;
      _foundProfile = null;
      _errorMsg = null;
    });

    final profile = await ref
        .read(technicianRepositoryProvider)
        .getProfileByPhone(_phoneCtrl.text.trim());

    setState(() {
      _isSearching = false;
      if (profile == null) {
        _errorMsg = 'لم يتم العثور على مستخدم مسجل بهذا الرقم.';
      } else if (profile['role'] == 'manager') {
        _errorMsg = 'لا يمكن ترقية مدير إلى فني.';
      } else if (profile['role'] == 'technician') {
        _errorMsg = 'هذا المستخدم فني مسبقاً.';
      } else {
        _foundProfile = profile;
      }
    });
  }

  Future<void> _promoteUser() async {
    if (_foundProfile == null) return;
    setState(() => _isPromoting = true);
    try {
      await ref
          .read(technicianRepositoryProvider)
          .promoteToTechnician(
            profileId: _foundProfile!['id'],
            phone: _foundProfile!['phone'],
            specialization: _specialization,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت الترقية إلى فني بنجاح!')),
      );
      if (mounted) context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _isPromoting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: const TammAppBar(title: 'إضافة فني جديد'),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'البحث عن مستخدم',
              style: GoogleFonts.harmattan(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TammTextField(
                      label: 'رقم الجوال',
                      hint: '05xxxxxxxx',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 28.0),
                    child: SizedBox(
                      height: 52,
                      width: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: AppColors.bluePrimary,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppSpacing.radius,
                          ),
                        ),
                        onPressed: _isSearching ? null : _searchByPhone,
                        child: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_errorMsg != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMsg!,
                  style: GoogleFonts.harmattan(
                    color: AppColors.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (_foundProfile != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'المستخدم المطابق:',
                style: GoogleFonts.harmattan(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: AppSpacing.radius,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _foundProfile!['full_name'] ?? 'بدون اسم',
                      style: GoogleFonts.harmattan(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _foundProfile!['phone'] ?? '',
                      style: GoogleFonts.harmattan(
                        fontSize: 14,
                        color: AppColors.textSecond,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'التخصص',
                      style: GoogleFonts.harmattan(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecond,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'مكيفات',
                          label: Text('مكيفات', style: GoogleFonts.harmattan()),
                        ),
                        ButtonSegment(
                          value: 'طاقة شمسية',
                          label: Text(
                            'طاقة شمسية',
                            style: GoogleFonts.harmattan(),
                          ),
                        ),
                      ],
                      selected: {_specialization},
                      onSelectionChanged: (s) =>
                          setState(() => _specialization = s.first),
                    ),
                    const SizedBox(height: 24),
                    TammButton(
                      label: 'ترقية إلى فني',
                      isLoading: _isPromoting,
                      onPressed: _promoteUser,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }
}
