import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_text_field.dart';

import '../../../../shared/providers/product_providers.dart';
import '../../../../shared/models/product.dart';
import '../../../../core/widgets/specs_editor.dart';
import '../../../../core/constants/product_specs.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;
  const ProductFormScreen({super.key, this.productId});
  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _oldPriceCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _installPriceCtrl = TextEditingController();
  String _category = 'ac';
  bool _requiresInstallation = false;
  bool _isFeatured = false;
  bool _loading = false;
  bool _isEdit = false;
  Map<String, dynamic> _specs = {};

  XFile? _selectedImage;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _isEdit = true;
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    final p = await ref
        .read(productRepositoryProvider)
        .getProduct(widget.productId!);
    _nameCtrl.text = p.name;
    _descCtrl.text = p.description ?? '';
    _priceCtrl.text = p.price?.toString() ?? '';
    _oldPriceCtrl.text = p.oldPrice?.toString() ?? '';
    _brandCtrl.text = p.brand ?? '';
    _installPriceCtrl.text = p.installationPrice > 0
        ? p.installationPrice.toString()
        : '';
    _category = p.category;
    _requiresInstallation = p.requiresInstallation;
    _isFeatured = p.isFeatured;
    _isFeatured = p.isFeatured;
    _existingImageUrl = p.imageUrl;
    _specs = Map<String, dynamic>.from(p.specs);
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = {
        'name': _nameCtrl.text,
        'description': _descCtrl.text.isEmpty ? null : _descCtrl.text,
        'category': _category,
        'brand': _brandCtrl.text.isEmpty ? null : _brandCtrl.text,
        'price': _priceCtrl.text.isEmpty ? null : double.parse(_priceCtrl.text),
        'old_price': _oldPriceCtrl.text.isEmpty
            ? null
            : double.parse(_oldPriceCtrl.text),
        'is_price_on_request': _priceCtrl.text.isEmpty,
        'requires_installation': _requiresInstallation,
        'installation_price': _installPriceCtrl.text.isEmpty
            ? 0.0
            : double.parse(_installPriceCtrl.text),
        'is_featured': _isFeatured,
        'specs': _specs,
      };

      if (_selectedImage != null) {
        final ext = _selectedImage!.path.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
        final bytes = await _selectedImage!.readAsBytes();
        await Supabase.instance.client.storage
            .from('products')
            .uploadBinary(fileName, bytes);
        final imageUrl = Supabase.instance.client.storage
            .from('products')
            .getPublicUrl(fileName);
        data['image_url'] = imageUrl;
      }

      if (_isEdit) {
        await ref
            .read(productRepositoryProvider)
            .updateProduct(widget.productId!, data);
      } else {
        await ref
            .read(productRepositoryProvider)
            .createProduct(
              Product(
                id: '',
                name: data['name'] as String,
                category: data['category'] as String,
                price: data['price'] as double?,
                isPriceOnRequest: data['is_price_on_request'] as bool,
                description: data['description'] as String?,
                brand: data['brand'] as String?,
                imageUrl: data['image_url'] as String?,
                requiresInstallation: data['requires_installation'] as bool,
                installationPrice: data['installation_price'] as double,
                oldPrice: data['old_price'] as double?,
                isFeatured: data['is_featured'] as bool,
                specs: data['specs'] as Map<String, dynamic>,
              ),
            );
      }
      ref.invalidate(productsProvider(null));
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
      appBar: TammAppBar(title: _isEdit ? 'تعديل منتج' : 'إضافة منتج'),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final img = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (img != null) {
                    setState(() => _selectedImage = img);
                  }
                },
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.colors.bgSurface2,
                    borderRadius: AppSpacing.radius,
                    border: Border.all(color: context.colors.border),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: AppSpacing.radius,
                          child: FutureBuilder<Uint8List>(
                            future: _selectedImage!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                );
                              }
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          ),
                        )
                      : _existingImageUrl != null
                      ? ClipRRect(
                          borderRadius: AppSpacing.radius,
                          child: Image.network(
                            _existingImageUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 40,
                              color: context.colors.textSecond,
                            ),
                            AppSpacing.gapSm,
                            Text(
                              'اضغط لإضافة صورة',
                              style: TextStyle(
                                color: context.colors.textSecond,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              AppSpacing.gapLg,
              TammTextField(
                label: 'اسم المنتج',
                controller: _nameCtrl,
                validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
              ),
              AppSpacing.gapSm2,
              TammTextField(label: 'الوصف', controller: _descCtrl, maxLines: 3),
              AppSpacing.gapSm2,
              DropdownButtonFormField<String>(
                initialValue: _category,
                dropdownColor: context.colors.bgSurface2,
                decoration: const InputDecoration(labelText: 'الفئة'),
                items: const [
                  DropdownMenuItem(value: 'ac', child: Text('مكيفات')),
                  DropdownMenuItem(
                    value: 'solar_panel',
                    child: Text('ألواح شمسية'),
                  ),
                  DropdownMenuItem(
                    value: 'solar_battery',
                    child: Text('بطاريات'),
                  ),
                  DropdownMenuItem(
                    value: 'solar_inverter',
                    child: Text('إنفرتر'),
                  ),
                  DropdownMenuItem(
                    value: 'accessory',
                    child: Text('إكسسوارات'),
                  ),
                ],
                onChanged: (v) {
                  setState(() {
                    _category = v!;
                    // Initialize default specs for the new category if not existing
                    final defaults = categoryDefaultSpecs[_category] ?? [];
                    for (final key in defaults) {
                      if (!_specs.containsKey(key)) {
                        _specs[key] = '';
                      }
                    }
                  });
                },
              ),
              AppSpacing.gapSm2,
              TammTextField(
                label: 'السعر الحالي (اتركه فارغ لطلب عرض سعر)',
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              AppSpacing.gapSm2,
              TammTextField(
                label: 'السعر قبل الخصم (اختياري، يظهر كعرض)',
                controller: _oldPriceCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              if (_oldPriceCtrl.text.isNotEmpty &&
                  _priceCtrl.text.isNotEmpty &&
                  (double.tryParse(_oldPriceCtrl.text) ?? 0) >
                      (double.tryParse(_priceCtrl.text) ?? 0)) ...[
                AppSpacing.gapSm2,
                Container(
                  padding: AppSpacing.cardPaddingSm,
                  decoration: BoxDecoration(
                    color: context.colors.success.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.radius,
                    border: Border.all(color: context.colors.success),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: context.colors.success),
                      AppSpacing.hGapSm,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '✅ هذا المنتج سيظهر كعرض خاص',
                              style: TextStyle(
                                color: context.colors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'الخصم: ${(((double.parse(_oldPriceCtrl.text) - double.parse(_priceCtrl.text)) / double.parse(_oldPriceCtrl.text)) * 100).round()}% | ~~${_oldPriceCtrl.text}~~ → ${_priceCtrl.text}',
                              style: TextStyle(
                                color: context.colors.textSecond,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              AppSpacing.gapSm2,
              TammTextField(label: 'العلامة التجارية', controller: _brandCtrl),
              AppSpacing.gapMd,
              SpecsEditor(
                initialSpecs: _specs,
                category: _category,
                onChanged: (specs) {
                  setState(() {
                    _specs = specs;
                  });
                },
              ),
              AppSpacing.gapMd,
              SwitchListTile(
                title: const Text('منتج مميز ⭐'),
                subtitle: const Text('يظهر في قسم "الأكثر طلباً" بالرئيسية'),
                value: _isFeatured,
                onChanged: (v) => setState(() => _isFeatured = v),
                activeThumbColor: context.colors.warning,
                contentPadding: EdgeInsets.zero,
              ),
              AppSpacing.gapMd,
              CheckboxListTile(
                title: const Text('هذا المنتج يتطلب خدمة تركيب؟'),
                value: _requiresInstallation,
                onChanged: (v) =>
                    setState(() => _requiresInstallation = v ?? false),
                activeColor: context.colors.bluePrimary,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_requiresInstallation) ...[
                AppSpacing.gapSm2,
                TammTextField(
                  label: 'سعر توصيل وتركيب المنتج (ريال)',
                  controller: _installPriceCtrl,
                  keyboardType: TextInputType.number,
                ),
              ],
              AppSpacing.gapLg,
              TammButton(
                label: _isEdit ? 'حفظ التعديلات' : 'إضافة',
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
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _oldPriceCtrl.dispose();
    _brandCtrl.dispose();
    _installPriceCtrl.dispose();
    super.dispose();
  }
}
