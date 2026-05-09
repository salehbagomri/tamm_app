import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_text_field.dart';
import '../../../../shared/models/service_type.dart';
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

  bool _isLoadingLocation = false;
  double? _lat, _lng;
  bool _locationPicked = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء تفعيل خدمات الموقع.')),
        );
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم رفض إذن الوصول للموقع.')),
          );
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'إذن الوصول للموقع مرفوض نهائياً. تم التعيين كموقع افتراضي.',
            ),
          ),
        );
        setState(() {
          _lat = 24.7136;
          _lng = 46.6753;
          _locationPicked = true;
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _locationPicked = true;
        _isLoadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر جلب الموقع، حاول مجدداً',
            style: GoogleFonts.harmattan(fontSize: 15),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _isLoadingLocation = false);
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
      final repo = ref.read(orderRepositoryProvider);
      final orderId = await repo.createOrder(
        orderType: 'quote_request',
        address: _addressController.text.trim(),
        total: 0.0,
        notes: _descriptionController.text.trim(),
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
      ref.invalidate(myOrdersProvider);
      ref.invalidate(allOrdersProvider(null));
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: context.colors.success),
                const SizedBox(width: 8),
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
              style: GoogleFonts.harmattan(fontSize: 15),
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
    final user = Supabase.instance.client.auth.currentUser;

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
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.colors.bluePrimary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: AppSpacing.radiusSm,
                            ),
                            child: Icon(
                              service.category.contains('ac_')
                                  ? Icons.ac_unit
                                  : service.category.contains('solar')
                                  ? Icons.solar_power
                                  : Icons.miscellaneous_services,
                              color: context.colors.bluePrimary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.name,
                                  style: GoogleFonts.harmattan(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: context.colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'تتطلب الخدمة معاينة أو تقييم لتقديم السعر',
                                  style: GoogleFonts.harmattan(
                                    fontSize: 14,
                                    color: context.colors.textSecond,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'وصف الاحتياج',
                      style: GoogleFonts.harmattan(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TammTextField(
                      label: 'أشرح تفاصيل الخدمة المطلوبة',
                      hint: 'مثال: أحتاج تركيب 3 مكيفات اسبليت بالدور الأول...',
                      controller: _descriptionController,
                      maxLines: 4,
                      onChanged: (val) => setState(() {}),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'الموقع',
                      style: GoogleFonts.harmattan(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
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
                        onTap: _isLoadingLocation ? null : _pickLocation,
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _locationPicked
                                    ? context.colors.success
                                    : context.colors.bluePrimary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _isLoadingLocation
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
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
                                          ? context.colors.success
                                          : context.colors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    _locationPicked
                                        ? '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'
                                        : 'اضغط لإرسال موقعك الدقيق للفني',
                                    style: GoogleFonts.harmattan(
                                      fontSize: 12,
                                      color: context.colors.textSecond,
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
                    const SizedBox(height: 16),
                    TammTextField(
                      label: 'العنوان بالتفصيل',
                      hint: 'المدينة، الحي، الشارع، رقم المبنى...',
                      controller: _addressController,
                      maxLines: 2,
                      onChanged: (val) => setState(() {}),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'رقم التواصل',
                      style: GoogleFonts.harmattan(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TammTextField(
                      label: 'الرقم المسجل في النظام',
                      hint: '',
                      controller: TextEditingController(
                        text: user?.phone ?? '',
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 24),
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
