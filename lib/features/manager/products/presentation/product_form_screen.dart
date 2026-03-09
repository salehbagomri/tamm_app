import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  String _category = 'ac';
  bool _loading = false;
  bool _isEdit = false;

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
    _category = p.category;
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
      };
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
    super.dispose();
  }
}
