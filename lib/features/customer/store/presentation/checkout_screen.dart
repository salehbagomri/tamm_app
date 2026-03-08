import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_text_field.dart';
import '../../../../shared/providers/order_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _timeSlot = 'صباحاً';
  bool _includeInstall = false;
  bool _loading = false;
  DateTime _preferredDate = DateTime.now().add(const Duration(days: 1));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cart = ref.read(cartProvider);
      final notifier = ref.read(cartProvider.notifier);
      final items = cart
          .map(
            (c) => {
              'item_type': 'product',
              'product_id': c.product.id,
              'quantity': c.quantity,
              'unit_price': c.product.price,
              'total_price': c.total,
            },
          )
          .toList();

      await ref
          .read(orderRepositoryProvider)
          .createOrder(
            orderType: _includeInstall ? 'product_and_service' : 'product',
            address: _addressCtrl.text,
            total: notifier.total,
            preferredDate: _preferredDate,
            timeSlot: _timeSlot,
            notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
            includeInstall: _includeInstall,
            items: items,
          );
      notifier.clear();
      if (mounted) context.go('/customer/order-success');
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
      appBar: const TammAppBar(title: 'إتمام الطلب'),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TammTextField(
                label: AppStrings.address,
                hint: 'العنوان بالتفصيل',
                controller: _addressCtrl,
                maxLines: 2,
                validator: (v) =>
                    v == null || v.isEmpty ? 'أدخل العنوان' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    AppStrings.preferredDate,
                    style: GoogleFonts.harmattan(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecond,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _preferredDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (d != null) setState(() => _preferredDate = d);
                    },
                    child: Text(
                      '${_preferredDate.day}/${_preferredDate.month}/${_preferredDate.year}',
                      style: GoogleFonts.harmattan(color: AppColors.blueLight),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'الفترة',
                    style: GoogleFonts.harmattan(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecond,
                    ),
                  ),
                  const Spacer(),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'صباحاً',
                        label: Text('صباحاً', style: GoogleFonts.harmattan()),
                      ),
                      ButtonSegment(
                        value: 'مساءً',
                        label: Text('مساءً', style: GoogleFonts.harmattan()),
                      ),
                    ],
                    selected: {_timeSlot},
                    onSelectionChanged: (s) =>
                        setState(() => _timeSlot = s.first),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TammTextField(
                label: AppStrings.notes,
                hint: 'ملاحظات إضافية (اختياري)',
                controller: _notesCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: Text(
                  AppStrings.includeInstall,
                  style: GoogleFonts.harmattan(color: AppColors.textPrimary),
                ),
                value: _includeInstall,
                onChanged: (v) => setState(() => _includeInstall = v!),
                activeColor: AppColors.bluePrimary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              TammButton(
                label: AppStrings.confirm,
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
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}
