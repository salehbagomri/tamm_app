import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_text_field.dart';
import '../../../../shared/models/service_type.dart';
import '../../../../shared/providers/manager_providers.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class ServiceFormScreen extends ConsumerStatefulWidget {
  final ServiceType? service;
  const ServiceFormScreen({super.key, this.service});

  @override
  ConsumerState<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends ConsumerState<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _includesCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  String _category = 'ac_install';
  bool _isQuoteBased = false;

  bool _loading = false;

  final Map<String, String> _categories = {
    'ac_install': 'تركيب مكيف',
    'ac_repair': 'صيانة مكيف',
    'ac_wash': 'غسيل مكيف',
    'ac_maintenance': 'متابعة دورية (مكيف)',
    'solar_install': 'تركيب طاقة شمسية',
    'solar_maintenance': 'صيانة منظومة شمسية',
    'consultation': 'استشارة فنية',
  };

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      final s = widget.service!;
      _nameCtrl.text = s.name;
      _descCtrl.text = s.description ?? '';
      _priceCtrl.text = s.basePrice?.toStringAsFixed(0) ?? '';
      _isQuoteBased = s.isQuoteBased;
      _includesCtrl.text = s.includes.join('\n');
      _durationCtrl.text = s.estimatedDuration ?? '';
      if (_categories.containsKey(s.category)) {
        _category = s.category;
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'category': _category,
        'base_price': double.tryParse(_priceCtrl.text) ?? 0.0,
        'is_quote_based': _isQuoteBased,
        'includes': _includesCtrl.text
            .trim()
            .split('\n')
            .where((e) => e.isNotEmpty)
            .toList(),
        'estimated_duration': _durationCtrl.text.trim().isEmpty
            ? null
            : _durationCtrl.text.trim(),
      };

      final repo = ref.read(serviceRepositoryProvider);

      if (widget.service == null) {
        // Add
        data['is_active'] = true;
        await repo.addServiceType(data);
      } else {
        // Edit
        await repo.updateServiceType(widget.service!.id, data);
      }

      ref.invalidate(managerServicesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.service == null
                  ? 'تمت إضافة الخدمة بنجاح'
                  : 'تم تحديث الخدمة بنجاح',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.bgPrimary,
        title: Text(
          widget.service == null ? 'إضافة خدمة جديدة' : 'تعديل الخدمة',
          style: AppTextStyles.h3(context.colors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TammTextField(
                label: 'اسم الخدمة',
                hint: 'مثال: غسيل مكيف سبليت',
                controller: _nameCtrl,
                validator: (val) =>
                    val == null || val.isEmpty ? 'حقل مطلوب' : null,
              ),
              AppSpacing.gapMd,
              Text(
                'تصنيف الخدمة',
                style: AppTextStyles.body(context.colors.textSecond),
              ),
              AppSpacing.gapSm,
              Container(
                decoration: BoxDecoration(
                  color: context.colors.bgSurface,
                  borderRadius: AppSpacing.radius,
                  border: Border.all(color: context.colors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _category,
                    isExpanded: true,
                    style: AppTextStyles.body(context.colors.textPrimary),
                    dropdownColor: context.colors.bgSurface,
                    items: _categories.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _category = val);
                    },
                  ),
                ),
              ),
              AppSpacing.gapMd,
              TammTextField(
                label: 'السعر الأساسي (ريال)',
                hint: '0',
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                validator: (val) =>
                    !_isQuoteBased && (val == null || val.isEmpty)
                    ? 'حقل مطلوب للسعر الثابت'
                    : null,
              ),
              AppSpacing.gapMd,
              CheckboxListTile(
                title: Text(
                  'خدمة عرض سعر (بدون سعر ثابت)',
                  style: AppTextStyles.body(context.colors.textPrimary),
                ),
                contentPadding: EdgeInsets.zero,
                value: _isQuoteBased,
                activeColor: context.colors.bluePrimary,
                onChanged: (val) {
                  if (val != null) setState(() => _isQuoteBased = val);
                },
              ),
              AppSpacing.gapMd,
              TammTextField(
                label: 'قائمة ما تشمله الخدمة (سطر لكل عنصر)',
                hint: 'شامل الفك\nشامل الفريون...',
                controller: _includesCtrl,
                maxLines: 4,
              ),
              AppSpacing.gapMd,
              TammTextField(
                label: 'مدة التنفيذ التقديرية',
                hint: 'مثال: ٢-٤ ساعات',
                controller: _durationCtrl,
              ),
              AppSpacing.gapMd,
              TammTextField(
                label: 'وصف الخدمة',
                hint: 'وصف قصير للخدمة...',
                controller: _descCtrl,
                maxLines: 4,
              ),
              AppSpacing.gapXl,
              TammButton(
                label: widget.service == null ? 'إضافة' : 'حفظ التعديلات',
                isLoading: _loading,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _includesCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }
}
