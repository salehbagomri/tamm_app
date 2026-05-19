import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_text_field.dart';
import '../../../../shared/providers/order_providers.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../services/widgets/appointment_display_card.dart';
import '../widgets/tamm_date_picker.dart';
import '../widgets/order_success_dialog.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';
import '../../../../shared/providers/auth_providers.dart';
import 'payment_method_selector.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final profile = await ref.read(userProfileProvider.future);
      if (mounted && _phoneCtrl.text.isEmpty && (profile?.phone ?? '').isNotEmpty) {
        _phoneCtrl.text = profile!.phone;
      }
    });
  }

  // Step navigation
  int _currentStep = 0;
  static const int _totalSteps = 4;

  // Step 1 — Location & Address
  final List<String> _cities = ['المكلا'];
  String _selectedCity = 'المكلا';
  double? _latitude;
  double? _longitude;
  bool _locationLoading = false;
  bool _locationPicked = false;

  // Step 2 — Appointment
  DateTime? _selectedDate;
  String? _selectedPeriod;
  String? _selectedHour;

  static const _periods = ['صباحاً', 'ظهراً', 'مساءً'];
  static const _periodTimes = {
    'صباحاً': '٨ص — ١٢م',
    'ظهراً': '١٢م — ٤م',
    'مساءً': '٤م — ٨م',
  };

  List<String> _hoursForPeriod(String period) {
    if (period == 'صباحاً') return ['٠٨:٠٠', '٠٩:٠٠', '١٠:٠٠', '١١:٠٠'];
    if (period == 'ظهراً') return ['١٢:٠٠', '٠١:٠٠', '٠٢:٠٠', '٠٣:٠٠'];
    if (period == 'مساءً') return ['٠٤:٠٠', '٠٥:٠٠', '٠٦:٠٠', '٠٧:٠٠'];
    return [];
  }

  // Step 3 — Payment
  String _paymentType = 'cash';
  String? _paymentMethodId;

  // Submission
  bool _loading = false;

  // ─── GPS ────────────────────────────────────────────
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

  // ─── Step Validation ────────────────────────────────
  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (_addressCtrl.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'الرجاء إدخال العنوان بالتفصيل',
                style: AppTextStyles.body(context.colors.textPrimary),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
        return true;
      case 1:
        if (_selectedDate == null || _selectedPeriod == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'الرجاء تحديد موعد',
                style: AppTextStyles.body(context.colors.textPrimary),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
        return true;
      case 2:
        if (_paymentType != 'cash' && _paymentMethodId == null) {
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
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (!_validateStep(_currentStep)) return;
    setState(() => _currentStep++);
  }

  void _prevStep() {
    setState(() => _currentStep--);
  }

  // ─── Submit ─────────────────────────────────────────
  Future<void> _submit() async {
    if (!await requireAuth(context, ref)) return;
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

      final orderResult = await ref
          .read(orderRepositoryProvider)
          .createOrder(
            orderType: hasInstallation ? 'product_and_service' : 'product',
            address: _addressCtrl.text,
            city: _selectedCity,
            total: notifier.total,
            preferredDate: _selectedDate,
            timeSlot: _selectedHour,
            scheduledPeriod: _selectedPeriod,
            scheduledHour: _selectedHour,
            notes: () {
              final parts = [
                if (_phoneCtrl.text.trim().isNotEmpty)
                  'رقم التواصل: ${_phoneCtrl.text.trim()}',
                if (_notesCtrl.text.trim().isNotEmpty) _notesCtrl.text.trim(),
              ];
              return parts.isEmpty ? null : parts.join('\n');
            }(),
            includeInstall: hasInstallation,
            latitude: _latitude,
            longitude: _longitude,
            paymentType: _paymentType,
            paymentMethodId: _paymentMethodId,
            items: items,
          );
      await notifier.clear();
      if (mounted) {
        await OrderSuccessDialog.show(
          context,
          orderId: orderResult.id,
          orderNumber: orderResult.orderNumber,
          paymentType: _paymentType,
        );
      }
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
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ─── Build ───────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: const TammAppBar(title: 'إتمام الطلب'),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: AppSpacing.pagePadding,
              child: _buildCurrentStep(),
            ),
          ),
          _buildNavigationBar(),
        ],
      ),
    );
  }

  // ─── Step Indicator ─────────────────────────────────
  Widget _buildStepIndicator() {
    const steps = [
      (label: 'الموقع', icon: Icons.location_on_outlined),
      (label: 'الموعد', icon: Icons.calendar_today_outlined),
      (label: 'الدفع', icon: Icons.credit_card_outlined),
      (label: 'التأكيد', icon: Icons.check_circle_outline),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm2,
      ),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        border: Border(bottom: BorderSide(color: context.colors.border)),
      ),
      child: Row(
        children: List.generate(_totalSteps * 2 - 1, (i) {
          if (i.isOdd) {
            final isCompleted = _currentStep > i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: isCompleted
                    ? context.colors.success
                    : context.colors.border,
              ),
            );
          }
          final idx = i ~/ 2;
          final isCompleted = _currentStep > idx;
          final isActive = _currentStep == idx;
          final step = steps[idx];

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? context.colors.success
                      : isActive
                          ? context.colors.bluePrimary
                          : context.colors.bgSurface2,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted
                        ? context.colors.success
                        : isActive
                            ? context.colors.bluePrimary
                            : context.colors.border,
                    width: 2,
                  ),
                ),
                child: Icon(
                  isCompleted ? Icons.check : step.icon,
                  size: AppSpacing.iconXs,
                  color: (isCompleted || isActive)
                      ? context.colors.bgSurface
                      : context.colors.textSecond,
                ),
              ),
              AppSpacing.gapXs,
              Text(
                step.label,
                style: AppTextStyles.caption(
                  isCompleted
                      ? context.colors.success
                      : isActive
                          ? context.colors.bluePrimary
                          : context.colors.textSecond,
                ).copyWith(
                  fontWeight:
                      isActive ? AppTextStyles.semiBold : AppTextStyles.regular,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildLocationStep();
      case 1:
        return _buildAppointmentStep();
      case 2:
        return _buildPaymentStep();
      case 3:
        return _buildConfirmStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Step 1: Location & Address ─────────────────────
  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpacing.gapMd,
        Text('المدينة', style: AppTextStyles.label(context.colors.textPrimary)),
        AppSpacing.gapSm,
        ..._cities.map((city) {
          final isSelected = _selectedCity == city;
          return GestureDetector(
            onTap: () => setState(() => _selectedCity = city),
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: isSelected
                    ? context.colors.success.withValues(alpha: 0.08)
                    : context.colors.bgSurface,
                borderRadius: AppSpacing.radiusLg,
                border: Border.all(
                  color: isSelected
                      ? context.colors.success
                      : context.colors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_city_outlined,
                    color: isSelected
                        ? context.colors.success
                        : context.colors.textSecond,
                    size: AppSpacing.iconMd,
                  ),
                  AppSpacing.hGapSm2,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📍 $city — التوصيل متاح',
                          style: AppTextStyles.body(
                            isSelected
                                ? context.colors.success
                                : context.colors.textPrimary,
                          ).copyWith(fontWeight: AppTextStyles.semiBold),
                        ),
                        if (isSelected) ...[
                          AppSpacing.gapXs,
                          Text(
                            'التوصيل متاح في المكلا حالياً',
                            style: AppTextStyles.caption(
                              context.colors.textSecond,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.success,
                        borderRadius: AppSpacing.radiusFull,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check,
                            size: AppSpacing.iconXs - 4,
                            color: context.colors.bgSurface,
                          ),
                          AppSpacing.hGapXs,
                          Text(
                            'محدد',
                            style: AppTextStyles.caption(
                              context.colors.bgSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
        AppSpacing.gapLg,
        Text(
          'الموقع الجغرافي',
          style: AppTextStyles.label(context.colors.textPrimary),
        ),
        AppSpacing.gapSm,
        // Prominent GPS card
        GestureDetector(
          onTap: _locationLoading ? null : _pickLocation,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: _locationPicked
                  ? context.colors.success.withValues(alpha: 0.08)
                  : context.colors.bluePrimary.withValues(alpha: 0.06),
              borderRadius: AppSpacing.radiusLg,
              border: Border.all(
                color: _locationPicked
                    ? context.colors.success
                    : context.colors.bluePrimary,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _locationPicked
                        ? context.colors.success
                        : context.colors.bluePrimary,
                    shape: BoxShape.circle,
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
                              ? Icons.check_circle_outline
                              : Icons.my_location,
                          color: context.colors.bgSurface,
                          size: AppSpacing.iconLg,
                        ),
                ),
                AppSpacing.gapSm2,
                Text(
                  _locationPicked ? 'تم تحديد الموقع ✓' : 'تحديد موقعي الحالي',
                  style: AppTextStyles.cardTitle(
                    _locationPicked
                        ? context.colors.success
                        : context.colors.bluePrimary,
                  ),
                ),
                AppSpacing.gapXs,
                Text(
                  _locationPicked
                      ? '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}'
                      : 'اضغط لإرسال موقعك الدقيق للفني',
                  style: AppTextStyles.caption(context.colors.textSecond),
                ),
                if (_locationPicked) ...[
                  AppSpacing.gapSm,
                  TextButton.icon(
                    onPressed: _pickLocation,
                    icon: Icon(
                      Icons.refresh,
                      size: AppSpacing.iconXs,
                      color: context.colors.textSecond,
                    ),
                    label: Text(
                      'تحديث الموقع',
                      style: AppTextStyles.caption(context.colors.textSecond),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        AppSpacing.gapLg,
        Text(
          'تفاصيل العنوان',
          style: AppTextStyles.label(context.colors.textPrimary),
        ),
        AppSpacing.gapSm,
        TammTextField(
          label: AppStrings.address,
          hint: 'مثال: الشرج، الشارع العام، بجانب جامع الشرج',
          controller: _addressCtrl,
          maxLines: 2,
          validator: (v) => v == null || v.isEmpty ? 'أدخل العنوان' : null,
        ),
        AppSpacing.gapLg,
        Text(
          'رقم التواصل',
          style: AppTextStyles.label(context.colors.textPrimary),
        ),
        AppSpacing.gapSm,
        TammTextField(
          label: 'رقم الهاتف',
          hint: '7XXXXXXXX',
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
        ),
        AppSpacing.gapLg,
      ],
    );
  }

  // ─── Step 2: Appointment ─────────────────────────────
  Widget _buildAppointmentStep() {
    final appointmentConfirmed =
        _selectedDate != null && _selectedPeriod != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpacing.gapMd,

        if (appointmentConfirmed) ...[
          // ── Confirmed: show summary card + edit button ──
          AppointmentDisplayCard(
            date: _selectedDate!,
            period: _selectedPeriod!,
            hour: _selectedHour,
          ),
          AppSpacing.gapSm2,
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() {
                _selectedDate = null;
                _selectedPeriod = null;
                _selectedHour = null;
              }),
              icon: Icon(
                Icons.edit_outlined,
                size: AppSpacing.iconXs,
                color: context.colors.bluePrimary,
              ),
              label: Text(
                'تعديل الموعد',
                style: AppTextStyles.body(context.colors.bluePrimary),
              ),
            ),
          ),
        ] else ...[
          // ── Picker: calendar → period → hour ────────────
          Text(
            'اختر التاريخ',
            style: AppTextStyles.label(context.colors.textPrimary),
          ),
          AppSpacing.gapSm,
          TammDatePicker(
            initialDate: _selectedDate,
            onDateSelected: (date) => setState(() {
              _selectedDate = date;
              _selectedPeriod = null;
              _selectedHour = null;
            }),
          ),

          if (_selectedDate != null) ...[
            AppSpacing.gapLg,
            Text(
              'اختر الفترة',
              style: AppTextStyles.label(context.colors.textPrimary),
            ),
            AppSpacing.gapSm,
            Row(
              children: List.generate(_periods.length, (i) {
                final period = _periods[i];
                final isSelected = _selectedPeriod == period;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedPeriod = period;
                      _selectedHour = null;
                    }),
                    child: Container(
                      margin: EdgeInsets.only(
                        left: i < _periods.length - 1 ? AppSpacing.sm : 0,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.colors.bluePrimary
                            : context.colors.bgSurface,
                        borderRadius: AppSpacing.radiusSm,
                        border: Border.all(
                          color: isSelected
                              ? context.colors.bluePrimary
                              : context.colors.border,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            period,
                            style: AppTextStyles.body(
                              isSelected
                                  ? context.colors.bgSurface
                                  : context.colors.textPrimary,
                            ).copyWith(fontWeight: AppTextStyles.bold),
                          ),
                          Text(
                            _periodTimes[period]!,
                            style: AppTextStyles.caption(
                              isSelected
                                  ? context.colors.bgSurface.withValues(
                                      alpha: 0.7,
                                    )
                                  : context.colors.textSecond,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],

          if (_selectedPeriod != null) ...[
            AppSpacing.gapLg,
            Row(
              children: [
                Text(
                  'اختر الوقت',
                  style: AppTextStyles.label(context.colors.textPrimary),
                ),
                AppSpacing.hGapXs,
                Text(
                  '(اختياري)',
                  style: AppTextStyles.bodySmall(context.colors.textSecond),
                ),
              ],
            ),
            AppSpacing.gapSm,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _hoursForPeriod(_selectedPeriod!).map((hour) {
                final isSelected = _selectedHour == hour;
                return GestureDetector(
                  onTap: () => setState(
                    () => _selectedHour = isSelected ? null : hour,
                  ),
                  child: Container(
                    width:
                        (MediaQuery.of(context).size.width -
                            AppSpacing.pageHorizontal * 2 -
                            AppSpacing.sm * 3) /
                        4,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.colors.bluePrimary
                          : context.colors.bgSurface,
                      borderRadius: AppSpacing.radiusSm,
                      border: Border.all(
                        color: isSelected
                            ? context.colors.bluePrimary
                            : context.colors.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      hour,
                      style: AppTextStyles.body(
                        isSelected
                            ? context.colors.bgSurface
                            : context.colors.textPrimary,
                      ).copyWith(fontWeight: AppTextStyles.bold),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],

        AppSpacing.gapLg,
      ],
    );
  }

  // ─── Step 3: Payment ─────────────────────────────────
  Widget _buildPaymentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpacing.gapMd,
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
      ],
    );
  }

  // ─── Step 4: Notes & Summary & Confirm ───────────────
  Widget _buildConfirmStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpacing.gapMd,
        TammTextField(
          label: AppStrings.notes,
          hint: 'ملاحظات إضافية (اختياري)',
          controller: _notesCtrl,
          maxLines: 3,
        ),
        AppSpacing.gapLg,
        _buildOrderSummary(),
        AppSpacing.gapLg,
      ],
    );
  }

  // ─── Navigation Bar ──────────────────────────────────
  Widget _buildNavigationBar() {
    final isLastStep = _currentStep == _totalSteps - 1;
    final isFirstStep = _currentStep == 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm2,
      ),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        border: Border(top: BorderSide(color: context.colors.border)),
      ),
      child: Row(
        children: [
          if (!isFirstStep) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, AppSpacing.buttonHeight),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppSpacing.radiusLg,
                  ),
                  side: BorderSide(color: context.colors.border),
                ),
                child: Text(
                  'السابق',
                  style: AppTextStyles.button(context.colors.textPrimary),
                ),
              ),
            ),
            AppSpacing.hGapSm2,
          ],
          Expanded(
            flex: 2,
            child: TammButton(
              label: isLastStep ? AppStrings.confirm : 'التالي',
              isLoading: _loading,
              onPressed: isLastStep ? _submit : _nextStep,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Order Summary ───────────────────────────────────
  Widget _buildOrderSummary() {
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
              children: cart.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                          padding: const EdgeInsets.only(
                            top: AppSpacing.xs,
                            right: AppSpacing.md,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.handyman_outlined,
                                    size: AppSpacing.iconXs - 2,
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
                );
              }).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorStateWidget(
              message:
                  e is AppException ? e.message : 'حدث خطأ في تحميل السلة',
              onRetry: () => ref.invalidate(cartProvider),
            ),
          ),
          const Divider(height: AppSpacing.lg),
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
