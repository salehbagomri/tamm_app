import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
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
  bool _loading = false;
  DateTime _preferredDate = DateTime.now().add(const Duration(days: 1));

  // GPS
  double? _latitude;
  double? _longitude;
  bool _locationLoading = false;
  bool _locationPicked = false;

  Future<void> _pickLocation() async {
    setState(() => _locationLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يجب السماح بالوصول للموقع')),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _locationPicked = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحديد الموقع: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cartAsync = ref.read(cartProvider);
      final notifier = ref.read(cartProvider.notifier);
      
      final items = cartAsync.maybeWhen(
        data: (cart) => cart.map<Map<String, dynamic>>((c) => {
          'item_type': 'product',
          'product_id': c.product.id,
          'quantity': c.quantity,
          // If installation is included for this product, add its price to the unit price for the order item record
          'unit_price': (c.product.price ?? 0) + (c.includeInstallation ? c.product.installationPrice : 0),
          'total_price': c.total,
        }).toList(),
        orElse: () => <Map<String, dynamic>>[],
      );

      if (items.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('السلة فارغة')),
          );
        }
        return;
      }

      // Check if any item in the cart includes installation
      final hasInstallation = cartAsync.maybeWhen(
        data: (cart) => cart.any((c) => c.includeInstallation),
        orElse: () => false,
      );

      final orderId = await ref
          .read(orderRepositoryProvider)
          .createOrder(
            orderType: hasInstallation ? 'product_and_service' : 'product',
            address: _addressCtrl.text,
            total: notifier.total,
            preferredDate: _preferredDate,
            timeSlot: _timeSlot,
            notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
            includeInstall: hasInstallation,
            latitude: _latitude,
            longitude: _longitude,
            items: items,
          );
      await notifier.clear();
      if (mounted) context.go('/customer/order-success/$orderId');
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderSummary(ref),
              const SizedBox(height: 24),
              // GPS Location Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _locationPicked
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.bgSurface,
                  borderRadius: AppSpacing.radiusLg,
                  border: Border.all(
                    color: _locationPicked
                        ? AppColors.success
                        : AppColors.border,
                  ),
                ),
                child: InkWell(
                  onTap: _locationLoading ? null : _pickLocation,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _locationPicked
                              ? AppColors.success
                              : AppColors.bluePrimary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _locationLoading
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _locationPicked
                                    ? Icons.check_circle
                                    : Icons.my_location,
                                color: Colors.white,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _locationPicked
                                  ? 'تم تحديد الموقع ✓'
                                  : '📍 تحديد موقعي الحالي',
                              style: GoogleFonts.harmattan(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _locationPicked
                                    ? AppColors.success
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              _locationPicked
                                  ? '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}'
                                  : 'اضغط لإرسال موقعك الدقيق للفني',
                              style: GoogleFonts.harmattan(
                                fontSize: 12,
                                color: AppColors.textSecond,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_locationPicked)
                        IconButton(
                          icon: const Icon(Icons.refresh, color: AppColors.textSecond),
                          onPressed: _pickLocation,
                          tooltip: 'تحديث الموقع',
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.money, color: AppColors.bluePrimary),
                  const SizedBox(width: 8),
                  Text(
                    'طريقة الدفع: كاش عند الاستلام',
                    style: GoogleFonts.harmattan(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              // We removed the old _includeInstall checkbox because it's now handled per-product in the cart
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

  Widget _buildOrderSummary(WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    return Container(
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
            'ملخص الطلب',
            style: GoogleFonts.harmattan(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          cartAsync.when(
            data: (cart) => Column(
              children: cart.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantity}x ${item.product.name}',
                            style: GoogleFonts.harmattan(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${((item.product.price ?? 0) * item.quantity).toInt()} ر.س',
                          style: GoogleFonts.harmattan(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (item.includeInstallation)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, right: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.handyman, size: 14, color: AppColors.bluePrimary),
                                const SizedBox(width: 4),
                                Text(
                                  'خدمة التركيب',
                                  style: GoogleFonts.harmattan(
                                    fontSize: 14,
                                    color: AppColors.bluePrimary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '+ ${item.product.installationPrice.toInt()} ر.س',
                              style: GoogleFonts.harmattan(
                                fontSize: 14,
                                color: AppColors.textSecond,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              )).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المبلغ الإجمالي',
                style: GoogleFonts.harmattan(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecond,
                ),
              ),
              Text(
                '${notifier.total.toInt()} ر.س',
                style: GoogleFonts.harmattan(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blueSky,
                ),
              ),
            ],
          ),
        ],
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
