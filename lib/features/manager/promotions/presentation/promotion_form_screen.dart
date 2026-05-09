import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_text_field.dart';
import '../../../../shared/models/promotion.dart';
import '../../../../shared/providers/promotion_providers.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class PromotionFormScreen extends ConsumerStatefulWidget {
  final Promotion? promotion;
  const PromotionFormScreen({super.key, this.promotion});

  @override
  ConsumerState<PromotionFormScreen> createState() =>
      _PromotionFormScreenState();
}

class _PromotionFormScreenState extends ConsumerState<PromotionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();

  String _iconName = 'local_offer';
  String _destination = '/customer/store';
  bool _isActive = true;
  bool _loading = false;

  // Specific list of pre-defined gradient presets as per plan
  String _selectedGradient = 'blue_dark';

  final Map<String, List<String>> _gradientOptions = {
    'blue_dark': ['#0A2540', '#0E4C8C'], // اشتر وركب
    'teal': ['#0A3540', '#0E6C8C'], // عروض مكيفات
    'green': ['#0A4020', '#0E8C4C'], // طاقة شمسية
    'purple': ['#2A0A40', '#5C0E8C'], // صيانة
    'orange': ['#6B2B06', '#A34208'], // اضافي
    'blue_sky': ['#0E508C', '#1A79CA'], // اضافي
  };

  @override
  void initState() {
    super.initState();
    if (widget.promotion != null) {
      final p = widget.promotion!;
      _titleCtrl.text = p.title;
      _subtitleCtrl.text = p.subtitle;
      _iconName = p.iconName;
      _destination = p.destination;
      _isActive = p.isActive;

      // Determine which gradient preset matches
      _selectedGradient = _gradientOptions.entries
          .firstWhere(
            (e) => e.value[0] == p.gradientStart && e.value[1] == p.gradientEnd,
            orElse: () => const MapEntry('blue_dark', ['#0A2540', '#0E4C8C']),
          )
          .key;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final gradientColors = _gradientOptions[_selectedGradient]!;

      final data = {
        'title': _titleCtrl.text,
        'subtitle': _subtitleCtrl.text,
        'icon_name': _iconName,
        'gradient_start': gradientColors[0],
        'gradient_end': gradientColors[1],
        'destination': _destination,
        'is_active': _isActive,
      };

      if (widget.promotion != null) {
        await ref
            .read(promotionRepositoryProvider)
            .updatePromotion(widget.promotion!.id, data);
      } else {
        await ref
            .read(promotionRepositoryProvider)
            .createPromotion(
              Promotion(
                id: '',
                title: data['title'] as String,
                subtitle: data['subtitle'] as String,
                iconName: data['icon_name'] as String,
                gradientStart: data['gradient_start'] as String,
                gradientEnd: data['gradient_end'] as String,
                destination: data['destination'] as String,
                sortOrder: 99, // default last
                isActive: data['is_active'] as bool,
              ),
            );
      }
      ref.invalidate(allPromotionsProvider);
      ref.invalidate(activePromotionsProvider);
      if (mounted) context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: TammAppBar(
        title: widget.promotion != null ? 'تعديل العرض' : 'إضافة عرض جديد',
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview Box
              Container(
                height: 120,
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(
                        int.parse(
                          _gradientOptions[_selectedGradient]![0].replaceAll(
                            '#',
                            '0xff',
                          ),
                        ),
                      ),
                      Color(
                        int.parse(
                          _gradientOptions[_selectedGradient]![1].replaceAll(
                            '#',
                            '0xff',
                          ),
                        ),
                      ),
                    ],
                  ),
                  borderRadius: AppSpacing.radiusLg,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _titleCtrl.text.isEmpty
                                ? 'عنوان العرض'
                                : _titleCtrl.text,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                          ),
                          Text(
                            _subtitleCtrl.text.isEmpty
                                ? 'تفاصيل العرض الفرعية'
                                : _subtitleCtrl.text,
                            style: const TextStyle(color: Colors.white70),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Promotion.iconMap[_iconName] ?? Icons.campaign,
                      color: Colors.white,
                      size: 32,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TammTextField(
                label: 'العنوان الرئيسي',
                controller: _titleCtrl,
                validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TammTextField(
                label: 'النص الفرعي',
                controller: _subtitleCtrl,
                validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _iconName,
                dropdownColor: context.colors.bgSurface2,
                decoration: const InputDecoration(labelText: 'الأيقونة'),
                items: Promotion.iconMap.keys.map((key) {
                  return DropdownMenuItem(
                    value: key,
                    child: Row(
                      children: [
                        Icon(Promotion.iconMap[key], size: 20),
                        const SizedBox(width: 12),
                        Text(key),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _iconName = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedGradient,
                dropdownColor: context.colors.bgSurface2,
                decoration: const InputDecoration(labelText: 'لون الخلفية'),
                items: const [
                  DropdownMenuItem(
                    value: 'blue_dark',
                    child: Text('تصميم أزرق غامق (افتراضي)'),
                  ),
                  DropdownMenuItem(
                    value: 'teal',
                    child: Text('تصميم أزرق مخضر (عروض)'),
                  ),
                  DropdownMenuItem(
                    value: 'green',
                    child: Text('تصميم أخضر (طاقة بديلة)'),
                  ),
                  DropdownMenuItem(
                    value: 'purple',
                    child: Text('تصميم بنفسجي (صيانة)'),
                  ),
                  DropdownMenuItem(
                    value: 'orange',
                    child: Text('تصميم برتقالي (تنبيهات)'),
                  ),
                  DropdownMenuItem(
                    value: 'blue_sky',
                    child: Text('تصميم أزرق فاتح'),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedGradient = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _destination,
                dropdownColor: context.colors.bgSurface2,
                decoration: const InputDecoration(
                  labelText: 'الوجهة عند الضغط',
                ),
                items: const [
                  DropdownMenuItem(
                    value: '/customer/store',
                    child: Text('المتجر'),
                  ),
                  DropdownMenuItem(
                    value: '/customer/services?category=ac_install',
                    child: Text('خدمات التركيب'),
                  ),
                  DropdownMenuItem(
                    value: '/customer/services?category=ac_repair',
                    child: Text('خدمات الصيانة'),
                  ),
                  DropdownMenuItem(
                    value: '/customer/services?category=consultation',
                    child: Text('طلب استشارة'),
                  ),
                ],
                onChanged: (v) => setState(() => _destination = v!),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('السلايدر نشط ويظهر للعملاء'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                activeThumbColor: context.colors.bluePrimary,
                contentPadding: EdgeInsets.zero,
              ),
              if (widget.promotion != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(promotionRepositoryProvider)
                        .deletePromotion(widget.promotion!.id);
                    ref.invalidate(allPromotionsProvider);
                    ref.invalidate(activePromotionsProvider);
                    if (context.mounted) context.pop();
                  },
                  icon: Icon(Icons.delete, color: context.colors.error),
                  label: Text(
                    'حذف هذا العرض',
                    style: TextStyle(color: context.colors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.colors.error),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              TammButton(
                label: widget.promotion != null ? 'حفظ التعديلات' : 'إضافة',
                isLoading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    super.dispose();
  }
}
