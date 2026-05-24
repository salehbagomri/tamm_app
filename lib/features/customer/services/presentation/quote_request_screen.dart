import '../../../../core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_text_field.dart';
import '../../../../shared/models/service_type.dart';
import '../../../../shared/providers/auth_providers.dart';
import '../../../../shared/providers/service_providers.dart';
import '../../../../shared/providers/order_providers.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class QuoteRequestScreen extends ConsumerStatefulWidget {
  final String serviceTypeId;
  const QuoteRequestScreen({super.key, required this.serviceTypeId});

  @override
  ConsumerState<QuoteRequestScreen> createState() => _QuoteRequestScreenState();
}

class _QuoteRequestScreenState extends ConsumerState<QuoteRequestScreen> {
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _phoneCtrl = TextEditingController();

  final List<String> _cities = ['المكلا'];
  String _selectedCity = 'المكلا';

  bool _isLoadingLocation = false;
  double? _lat, _lng;
  bool _locationPicked = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final profile = await ref.read(userProfileProvider.future);
      if (mounted &&
          _phoneCtrl.text.isEmpty &&
          (profile?.phone ?? '').isNotEmpty) {
        _phoneCtrl.text = profile!.phone;
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    setState(() => _isLoadingLocation = true);
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
        _lat = pos.latitude;
        _lng = pos.longitude;
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
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  bool _isFormValid() {
    return _descriptionController.text.trim().isNotEmpty &&
        _addressController.text.trim().isNotEmpty;
  }

  Future<void> _submitQuoteRequest(ServiceType service) async {
    if (!_isFormValid()) return;
    setState(() => _isSubmitting = true);
    try {
      final phoneText = _phoneCtrl.text.trim();
      final notesText = _notesController.text.trim();
      final parts = [
        if (phoneText.isNotEmpty) 'رقم التواصل: $phoneText',
        _descriptionController.text.trim(),
        if (notesText.isNotEmpty) notesText,
      ];
      final repo = ref.read(orderRepositoryProvider);
      final orderResult = await repo.createOrder(
        orderType: 'quote_request',
        address: _addressController.text.trim(),
        city: _selectedCity,
        total: 0.0,
        notes: parts.join('\n'),
        latitude: _lat,
        longitude: _lng,
        includeInstall: false,
        quoteStatus: 'pending',
        items: [
          {
            'item_type': 'service',
            'service_type_id': service.id,
            'quantity': 1,
            'unit_price': 0.0,
            'total_price': 0.0,
          },
        ],
      );
      final orderId = orderResult.id;
      ref.invalidate(myOrdersProvider);
      ref.invalidate(allOrdersProvider(null));
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle_outline, color: context.colors.success),
                AppSpacing.hGapSm,
                const Text('تم الإرسال بنجاح'),
              ],
            ),
            content: const Text(
              'لقد استلمنا طلب العرض الخاص بك. سيقوم فريقنا بمراجعته وإرسال تفاصيل السعر قريباً.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.go('/customer/home');
                  context.push('/customer/order/$orderId');
                },
                child: const Text('تتبع الطلب'),
              ),
              TammButton(
                label: 'الرئيسية',
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.go('/customer/home');
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ أثناء إرسال الطلب، حاول مجدداً',
              style: AppTextStyles.bodySmall(context.colors.textPrimary),
            ),
            backgroundColor: context.colors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceAsync = ref.watch(serviceDetailProvider(widget.serviceTypeId));

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: const TammAppBar(title: 'طلب عرض سعر'),
      body: serviceAsync.when(
        data: (service) => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TammCard(
                      child: Row(
                        children: [
                          Container(
                            padding: AppSpacing.cardPaddingSm,
                            decoration: BoxDecoration(
                              color: context.colors.bluePrimary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: AppSpacing.radiusSm,
                            ),
                            child: Icon(
                              service.category.contains('ac_')
                                  ? Icons.ac_unit_outlined
                                  : service.category.contains('solar')
                                  ? Icons.solar_power_outlined
                                  : Icons.miscellaneous_services_outlined,
                              color: context.colors.bluePrimary,
                            ),
                          ),
                          AppSpacing.hGapMd,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.name,
                                  style: AppTextStyles.cardTitle(
                                    context.colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'تتطلب الخدمة معاينة أو تقييم لتقديم السعر',
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
                    AppSpacing.gapLg,
                    Text(
                      'وصف الاحتياج',
                      style: AppTextStyles.cardTitle(
                        context.colors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapSm,
                    TammTextField(
                      label: 'أشرح تفاصيل الخدمة المطلوبة',
                      hint: 'مثال: أحتاج تركيب 3 مكيفات اسبليت بالدور الأول...',
                      controller: _descriptionController,
                      maxLines: 4,
                      onChanged: (val) => setState(() {}),
                    ),
                    AppSpacing.gapLg,
                    Text(
                      'المدينة',
                      style: AppTextStyles.label(context.colors.textPrimary),
                    ),
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
                                      '📍 $city — الخدمة متاحة',
                                      style:
                                          AppTextStyles.body(
                                            isSelected
                                                ? context.colors.success
                                                : context.colors.textPrimary,
                                          ).copyWith(
                                            fontWeight: AppTextStyles.semiBold,
                                          ),
                                    ),
                                    if (isSelected) ...[
                                      AppSpacing.gapXs,
                                      Text(
                                        'الخدمة متاحة في المكلا حالياً',
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
                    GestureDetector(
                      onTap: _isLoadingLocation ? null : _pickLocation,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: _locationPicked
                              ? context.colors.success.withValues(alpha: 0.08)
                              : context.colors.bluePrimary.withValues(
                                  alpha: 0.06,
                                ),
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
                              child: _isLoadingLocation
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
                              _locationPicked
                                  ? 'تم تحديد الموقع ✓'
                                  : 'تحديد موقعي الحالي',
                              style: AppTextStyles.cardTitle(
                                _locationPicked
                                    ? context.colors.success
                                    : context.colors.bluePrimary,
                              ),
                            ),
                            AppSpacing.gapXs,
                            Text(
                              _locationPicked
                                  ? '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'
                                  : 'اضغط لإرسال موقعك الدقيق للفني',
                              style: AppTextStyles.caption(
                                context.colors.textSecond,
                              ),
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
                                  style: AppTextStyles.caption(
                                    context.colors.textSecond,
                                  ),
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
                      label: 'العنوان بالتفصيل',
                      hint: 'مثال: الشرج، الشارع العام، بجانب جامع الشرج',
                      controller: _addressController,
                      maxLines: 2,
                      onChanged: (val) => setState(() {}),
                    ),
                    AppSpacing.gapLg,
                    Text(
                      'رقم التواصل',
                      style: AppTextStyles.cardTitle(
                        context.colors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapSm,
                    TammTextField(
                      label: 'رقم الهاتف',
                      hint: '7XXXXXXXX',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                    ),
                    AppSpacing.gapLg,
                    TammTextField(
                      label: 'ملاحظات إضافية (اختياري)',
                      hint: 'أي معلومات قد تهمنا...',
                      controller: _notesController,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.colors.bgSurface,
                border: Border(top: BorderSide(color: context.colors.border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: TammButton(
                label: 'اطلب عرض سعر',
                icon: Icons.send_rounded,
                isLoading: _isSubmitting,
                onPressed: _isFormValid()
                    ? () => _submitQuoteRequest(service)
                    : null,
              ),
            ),
          ],
        ),
        loading: () => const TammLoading(),
        error: (e, _) => ErrorStateWidget(
          message: e is AppException ? e.message : 'حدث خطأ في تحميل الخدمة',
          onRetry: () =>
              ref.refresh(serviceDetailProvider(widget.serviceTypeId)),
        ),
      ),
    );
  }
}
