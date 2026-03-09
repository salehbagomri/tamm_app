import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_text_field.dart';
import '../../../../shared/models/service_type.dart';
import '../../../../shared/providers/manager_providers.dart';

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
  String _category = 'ac_install';

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
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        title: Text(
          widget.service == null ? 'إضافة خدمة جديدة' : 'تعديل الخدمة',
          style: GoogleFonts.harmattan(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
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
              const SizedBox(height: 16),
              Text(
                'تصنيف الخدمة',
                style: GoogleFonts.harmattan(
                  fontSize: 16,
                  color: AppColors.textSecond,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _category,
                    isExpanded: true,
                    style: GoogleFonts.harmattan(
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                    dropdownColor: AppColors.bgSurface,
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
              const SizedBox(height: 16),
              TammTextField(
                label: 'السعر الأساسي (ريال)',
                hint: '0',
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                validator: (val) =>
                    val == null || val.isEmpty ? 'حقل مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TammTextField(
                label: 'وصف الخدمة',
                hint: 'وصف قصير للخدمة...',
                controller: _descCtrl,
                maxLines: 4,
              ),
              const SizedBox(height: 32),
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
    super.dispose();
  }
}
