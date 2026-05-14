import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_text_field.dart';
import '../../../../shared/providers/order_providers.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../services/widgets/appointment_picker.dart';
import '../../services/widgets/appointment_display_card.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';
import 'payment_method_selector.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedPeriod;
  String? _selectedHour;
  bool _loading = false;
  String _paymentType = 'cash';
  String? _paymentMethodId;

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
            const SnackBar(
              content: Text('يجب السماح بالوصول للموقع'),
              behavior: SnackBarBehavior.floating,
            ),
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
          SnackBar(
            content: Text('تعذر تحديد الموقع: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!await requireAuth(context, ref)) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedPeriod == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء تحديد موعد'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    if (_paymentType != 'cash' && _paymentMethodId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'يرجى اختيار طريقة الدفع',
              style: AppTextStyles.body(context.colors.textPrimary),
            ),
            backgroundColor: context.colors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    setState(() => _loading = true);
    try {
      final cartAsync = ref.read(cartProvider);
      final notifier = ref.read(cartProvider.notifier);

      final items = cartAsync.maybeWhen(
        data: (cart) => cart
            .map<Map<String, dynamic>>(
              (c) => {
                'item_type': 'product',
                'product_id': c.product.id,
                'quantity': c.quantity,
                'unit_price':
                    (c.product.price ?? 0) +
                    (c.includeInstallation ? c.product.installationPrice : 0),
                'total_price': c.total,
              },
            )
            .toList(),
        orElse: () => <Map<String, dynamic>>[],
      );

      if (items.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('السلة فارغة'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

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
            preferredDate: _selectedDate,
            timeSlot: _selectedHour,
            scheduledPeriod: _selectedPeriod,
            scheduledHour: _selectedHour,
            notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
            includeInstall: hasInstallation,
            latitude: _latitude,
            longitude: _longitude,
            paymentType: _paymentType,
            paymentMethodId: _paymentMethodId,
            items: items,
          );
      await notifier.clear();
      if (mounted) context.go('/customer/order-success/$orderId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AppException ? e.message : 'حدث خطأ في إتمام الطلب',
              style: AppTextStyles.body(context.colors.textPrimary),
            ),
            backgroundColor: context.colors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: const TammAppBar(title: 'إتمام الطلب'),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderSummary(ref),
              AppSpacing.gapLg,
              // GPS Location Button
              Container(
                width: double.infinity,
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: _locationPicked
                      ? context.colors.success.withValues(alpha: 0.1)
                      : context.colors.bgSurface,
                  borderRadius: AppSpacing.radiusLg,
                  border: Border.all(
                    color: _locationPicked
                        ? context.colors.success
                        : context.colors.border,
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
                              ? context.colors.success
                              : context.colors.bluePrimary,
                          borderRadius: AppSpacing.radius,
                        ),
                        child: _locationLoading
                            ? const Padding(
                                padding: AppSpacing.iconCirclePadding,
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
                      AppSpacing.hGapSm2,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _locationPicked
                                  ? 'تم تحديد الموقع ✓'
                                  : '📍 تحديد موقعي الحالي',
                              style: AppTextStyles.body(
                                _locationPicked
                                    ? context.colors.success
                                    : context.colors.textPrimary,
                              ).copyWith(fontWeight: AppTextStyles.bold),
                            ),
                            Text(
                              _locationPicked
                                  ? '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}'
                                  : 'اضغط لإرسال موقعك الدقيق للفني',
                              style: AppTextStyles.caption(
                                context.colors.textSecond,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_locationPicked)
                        IconButton(
                          icon: Icon(
                            Icons.refresh,
                            color: context.colors.textSecond,
                          ),
                          onPressed: _pickLocation,
                          tooltip: 'تحديث الموقع',
                        ),
                    ],
                  ),
                ),
              ),
              AppSpacing.gapMd,
              TammTextField(
                label: AppStrings.address,
                hint: 'العنوان بالتفصيل',
                controller: _addressCtrl,
                maxLines: 2,
                validator: (v) =>
                    v == null || v.isEmpty ? 'أدخل العنوان' : null,
              ),
              AppSpacing.gapLg,
              Text(
                'حدد الموعد',
                style: AppTextStyles.cardTitle(context.colors.textPrimary),
              ),
              AppSpacing.gapSm2,
              if (_selectedDate != null && _selectedPeriod != null) ...[
                AppointmentDisplayCard(
                  date: _selectedDate!,
                  period: _selectedPeriod!,
                  hour: _selectedHour,
                ),
                AppSpacing.gapMd,
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedDate = null;
                        _selectedPeriod = null;
                        _selectedHour = null;
                      });
                    },
                    icon: Icon(
                      Icons.edit,
                      size: 16,
                      color: context.colors.bluePrimary,
                    ),
                    label: Text(
                      'تعديل الموعد',
                      style: AppTextStyles.body(context.colors.textPrimary),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: AppSpacing.cardPadding,
                  decoration: BoxDecoration(
                    color: context.colors.bgSurface,
                    borderRadius: AppSpacing.radiusLg,
                    border: Border.all(color: context.colors.border),
                  ),
                  child: AppointmentPicker(
                    initialDate: _selectedDate,
                    onDateSelected: (date, period, hour) {
                      setState(() {
                        _selectedDate = date;
                        _selectedPeriod = period;
                        _selectedHour = hour;
                      });
                    },
                  ),
                ),
              ],
              AppSpacing.gapLg,
              TammTextField(
                label: AppStrings.notes,
                hint: 'ملاحظات إضافية (اختياري)',
                controller: _notesCtrl,
                maxLines: 3,
              ),
              AppSpacing.gapLg,
              PaymentMethodSelector(
                selectedType: _paymentType,
                selectedMethodId: _paymentMethodId,
                onChanged: (type, methodId) {
                  setState(() {
                    _paymentType = type;
                    _paymentMethodId = methodId;
                  });
                },
              ),
              AppSpacing.gapLg,
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
            'ملخص الطلب',
            style: AppTextStyles.cardTitle(context.colors.textPrimary),
          ),
          AppSpacing.gapSm2,
          cartAsync.when(
            data: (cart) => Column(
              children: cart
                  .map(
                    (item) => Padding(
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
                                  style: AppTextStyles.body(
                                    context.colors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${((item.product.price ?? 0) * item.quantity).toInt()} ر.س',
                                style: AppTextStyles.body(
                                  context.colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (item.includeInstallation)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, right: 16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.handyman,
                                        size: 14,
                                        color: context.colors.bluePrimary,
                                      ),
                                      AppSpacing.hGapXs,
                                      Text(
                                        'خدمة التركيب',
                                        style: AppTextStyles.bodySmall(
                                          context.colors.bluePrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '+ ${item.product.installationPrice.toInt()} ر.س',
                                    style: AppTextStyles.bodySmall(
                                      context.colors.textSecond,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorStateWidget(
              message: e is AppException ? e.message : 'حدث خطأ في تحميل السلة',
              onRetry: () => ref.invalidate(cartProvider),
            ),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المبلغ الإجمالي',
                style: AppTextStyles.body(
                  context.colors.textSecond,
                ).copyWith(fontWeight: AppTextStyles.bold),
              ),
              Text(
                '${notifier.total.toInt()} ر.س',
                style: AppTextStyles.sectionTitle(context.colors.blueSky),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
