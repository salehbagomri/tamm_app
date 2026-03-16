import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_text_field.dart';

import '../../../../shared/providers/product_providers.dart';
import '../../../../shared/models/product.dart';

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
  final _brandCtrl = TextEditingController();
  final _installPriceCtrl = TextEditingController();
  String _category = 'ac';
  bool _requiresInstallation = false;
  bool _loading = false;
  bool _isEdit = false;

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
    _brandCtrl.text = p.brand ?? '';
    _installPriceCtrl.text = p.installationPrice > 0 ? p.installationPrice.toString() : '';
    _category = p.category;
    _requiresInstallation = p.requiresInstallation;
    _existingImageUrl = p.imageUrl;
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
        'is_price_on_request': _priceCtrl.text.isEmpty,
        'requires_installation': _requiresInstallation,
        'installation_price': _installPriceCtrl.text.isEmpty ? 0.0 : double.parse(_installPriceCtrl.text),
      };

      if (_selectedImage != null) {
        final ext = _selectedImage!.path.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
        await Supabase.instance.client.storage
            .from('products')
            .upload(fileName, File(_selectedImage!.path));
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
      backgroundColor: AppColors.bgPrimary,
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
                    color: AppColors.bgSurface2,
                    borderRadius: AppSpacing.radius,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: AppSpacing.radius,
                          child: Image.file(
                            File(_selectedImage!.path),
                            fit: BoxFit.cover,
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
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 40,
                              color: AppColors.textSecond,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'اضغط لإضافة صورة',
                              style: TextStyle(color: AppColors.textSecond),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              TammTextField(
                label: 'اسم المنتج',
                controller: _nameCtrl,
                validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TammTextField(label: 'الوصف', controller: _descCtrl, maxLines: 3),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                dropdownColor: AppColors.bgSurface2,
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
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),
              TammTextField(
                label: 'السعر (اتركه فارغ لطلب عرض سعر)',
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TammTextField(label: 'العلامة التجارية', controller: _brandCtrl),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('هذا المنتج يتطلب خدمة تركيب؟'),
                value: _requiresInstallation,
                onChanged: (v) => setState(() => _requiresInstallation = v ?? false),
                activeColor: AppColors.bluePrimary,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_requiresInstallation) ...[
                const SizedBox(height: 12),
                TammTextField(
                  label: 'سعر توصيل وتركيب المنتج (ريال)',
                  controller: _installPriceCtrl,
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 24),
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
    _brandCtrl.dispose();
    _installPriceCtrl.dispose();
    super.dispose();
  }
}
