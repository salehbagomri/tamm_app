import '../../../../core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_text_field.dart';
import '../../../../shared/providers/manager_providers.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

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
      backgroundColor: context.colors.bgPrimary,
      appBar: const TammAppBar(title: 'إضافة فني جديد'),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'البحث عن مستخدم',
              style: AppTextStyles.cardTitle(context.colors.textPrimary),
            ),
            AppSpacing.gapMd,
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
                  AppSpacing.hGapSm,
                  Padding(
                    padding: const EdgeInsets.only(top: 28.0),
                    child: SizedBox(
                      height: 52,
                      width: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: context.colors.bluePrimary,
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
                  style: AppTextStyles.body(context.colors.textPrimary),
                ),
              ),
            if (_foundProfile != null) ...[
              AppSpacing.gapLg,
              const Divider(),
              AppSpacing.gapMd,
              Text(
                'المستخدم المطابق:',
                style: AppTextStyles.cardTitle(context.colors.textPrimary),
              ),
              AppSpacing.gapSm2,
              Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: context.colors.bgSurface,
                  borderRadius: AppSpacing.radius,
                  border: Border.all(color: context.colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _foundProfile!['full_name'] ?? 'بدون اسم',
                      style: AppTextStyles.cardTitle(
                        context.colors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapXs,
                    Text(
                      _foundProfile!['phone'] ?? '',
                      style: AppTextStyles.bodySmall(context.colors.textSecond),
                    ),
                    AppSpacing.gapMd,
                    Text(
                      'التخصص',
                      style: AppTextStyles.bodySmall(
                        context.colors.textSecond,
                      ).copyWith(fontWeight: AppTextStyles.bold),
                    ),
                    AppSpacing.gapSm,
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'مكيفات',
                          label: Text(
                            'مكيفات',
                            style: AppTextStyles.body(
                              context.colors.textPrimary,
                            ),
                          ),
                        ),
                        ButtonSegment(
                          value: 'طاقة شمسية',
                          label: Text(
                            'طاقة شمسية',
                            style: AppTextStyles.body(
                              context.colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                      selected: {_specialization},
                      onSelectionChanged: (s) =>
                          setState(() => _specialization = s.first),
                    ),
                    AppSpacing.gapLg,
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
