import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_text_field.dart';
import '../../../../shared/models/service_type.dart';
import '../../../../shared/providers/order_providers.dart';
import '../../../../shared/providers/service_providers.dart';
import '../widgets/appointment_display_card.dart';
import '../widgets/appointment_picker.dart';
import '../widgets/service_summary_card.dart';
import '../../../../core/errors/app_exception.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class ServiceRequestScreen extends ConsumerStatefulWidget {
  final String serviceTypeId;
  const ServiceRequestScreen({super.key, required this.serviceTypeId});

  @override
  ConsumerState<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends ConsumerState<ServiceRequestScreen> {
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoadingLocation = false;
  double? _lat, _lng;
  bool _locationPicked = false;

  DateTime? _selectedDate;
  String? _selectedPeriod;
  String? _selectedHour;

  bool _isSubmitting = false;

  @override
  void dispose() {
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
          const SnackBar(content: Text('الرجاء تفعيل خدمات الموقع.'), behavior: SnackBarBehavior.floating),
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
            const SnackBar(content: Text('تم رفض إذن الوصول للموقع.'), behavior: SnackBarBehavior.floating),
          );
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('إذن الوصول للموقع مرفوض نهائياً. تم التعيين كموقع افتراضي.'),
            behavior: SnackBarBehavior.floating,
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

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _locationPicked = true;
        _isLoadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e is AppException ? e.message : 'حدث خطأ أثناء جلب الموقع',
          style: GoogleFonts.harmattan(fontSize: 15),
        ),
        backgroundColor: context.colors.error,
        behavior: SnackBarBehavior.floating,
      ));
      setState(() => _isLoadingLocation = false);
    }
  }

  bool _isFormValid() {
    return _addressController.text.trim().isNotEmpty &&
        _selectedDate != null &&
        _selectedPeriod != null;
  }

  Future<void> _submitOrder(ServiceType service) async {
    if (!_isFormValid()) return;
    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      final orderId = await repo.createOrder(
        orderType: 'service',
        address: _addressController.text.trim(),
        total: service.basePrice ?? 0.0,
        preferredDate: _selectedDate,
        timeSlot: _selectedHour,
        notes: _notesController.text.trim(),
        latitude: _lat,
        longitude: _lng,
        includeInstall: false,
        scheduledPeriod: _selectedPeriod,
        scheduledHour: _selectedHour,
        items: [
          {
            'item_type': 'service',
            'service_type_id': service.id,
            'quantity': 1,
            'unit_price': service.basePrice ?? 0.0,
            'total_price': service.basePrice ?? 0.0,
          }
        ],
      );
      ref.invalidate(myOrdersProvider);
      ref.invalidate(allOrdersProvider(null));
      if (mounted) {
        context.push('/customer/booking-confirmation/$orderId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            e is AppException ? e.message : 'حدث خطأ في إتمام الحجز',
            style: GoogleFonts.harmattan(fontSize: 15),
          ),
          backgroundColor: context.colors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ));
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
      appBar: const TammAppBar(title: 'طلب خدمة'),
      body: serviceAsync.when(
        data: (service) => _buildBody(context, service),
        loading: () => const TammLoading(),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('حدث خطأ في تحميل الخدمة', style: GoogleFonts.harmattan(fontSize: 18)),
              const SizedBox(height: 16),
              TammButton(
                label: 'حاول مجدداً',
                onPressed: () => ref.invalidate(serviceDetailProvider(widget.serviceTypeId)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ServiceType service) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('التفاصيل الأساسية', style: GoogleFonts.harmattan(fontSize: 20, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
                const SizedBox(height: 12),
                TammCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.colors.bluePrimary.withValues(alpha: 0.1),
                          borderRadius: AppSpacing.radiusSm,
                        ),
                        child: Icon(
                          service.category.contains('ac_') ? Icons.ac_unit :
                          service.category.contains('solar') ? Icons.solar_power : Icons.miscellaneous_services,
                          color: context.colors.bluePrimary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(service.name, style: GoogleFonts.harmattan(fontSize: 18, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
                            Text(
                              service.basePrice != null ? '${service.basePrice!.toInt()} ر.س' : 'يُحدد لاحقاً',
                              style: GoogleFonts.harmattan(fontSize: 16, color: context.colors.blueSky),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text('حدد الموقع', style: GoogleFonts.harmattan(fontSize: 20, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _locationPicked ? context.colors.success.withValues(alpha: 0.1) : context.colors.bgSurface,
                    borderRadius: AppSpacing.radiusLg,
                    border: Border.all(color: _locationPicked ? context.colors.success : context.colors.border),
                  ),
                  child: InkWell(
                    onTap: _isLoadingLocation ? null : _pickLocation,
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _locationPicked ? context.colors.success : context.colors.bluePrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _isLoadingLocation
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Icon(_locationPicked ? Icons.check_circle : Icons.my_location, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _locationPicked ? 'تم تحديد الموقع ✓' : '📍 تحديد موقعي الحالي',
                                style: GoogleFonts.harmattan(fontSize: 16, fontWeight: FontWeight.w700, color: _locationPicked ? context.colors.success : context.colors.textPrimary),
                              ),
                              Text(
                                _locationPicked ? '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}' : 'اضغط لإرسال موقعك الدقيق للفني',
                                style: GoogleFonts.harmattan(fontSize: 12, color: context.colors.textSecond),
                              ),
                            ],
                          ),
                        ),
                        if (_locationPicked)
                          IconButton(icon: Icon(Icons.refresh, color: context.colors.textSecond), onPressed: _pickLocation, tooltip: 'تحديث الموقع'),
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
                const SizedBox(height: 32),
                Text('حدد الموعد', style: GoogleFonts.harmattan(fontSize: 20, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
                const SizedBox(height: 12),
                if (_selectedDate != null && _selectedPeriod != null) ...[
                  AppointmentDisplayCard(date: _selectedDate!, period: _selectedPeriod!, hour: _selectedHour),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => setState(() { _selectedDate = null; _selectedPeriod = null; _selectedHour = null; }),
                      icon: const Icon(Icons.edit, size: 16),
                      label: Text('تعديل الموعد', style: GoogleFonts.harmattan(fontSize: 16)),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: context.colors.bgSurface, borderRadius: AppSpacing.radiusLg, border: Border.all(color: context.colors.border)),
                    child: AppointmentPicker(
                      initialDate: _selectedDate,
                      onDateSelected: (date, period, hour) {
                        setState(() { _selectedDate = date; _selectedPeriod = period; _selectedHour = hour; });
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Text('أضف ملاحظات (اختياري)', style: GoogleFonts.harmattan(fontSize: 20, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
                const SizedBox(height: 12),
                TammTextField(
                  label: 'أي تفاصيل إضافية تساعد الفني...',
                  hint: 'مثال: المكيف في الدور الثاني...',
                  controller: _notesController,
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ),
        if (_isFormValid())
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ServiceSummaryCard(
                service: service,
                locationText: _addressController.text.trim(),
                date: _selectedDate!,
                period: _selectedPeriod!,
                hour: _selectedHour,
              ),
              Container(
                color: context.colors.bgSurface,
                padding: EdgeInsets.only(left: 24, right: 24, bottom: MediaQuery.of(context).padding.bottom + 16, top: 8),
                child: TammButton(label: 'تأكيد الحجز', isLoading: _isSubmitting, onPressed: () => _submitOrder(service)),
              ),
            ],
          )
        else
          Container(
            padding: EdgeInsets.only(left: 24, right: 24, bottom: MediaQuery.of(context).padding.bottom + 16, top: 16),
            decoration: BoxDecoration(color: context.colors.bgSurface, border: Border(top: BorderSide(color: context.colors.border))),
            child: TammButton(label: 'أكمل البيانات المطلوبة لحجز الخدمة', type: TammButtonType.secondary, onPressed: () {}),
          ),
      ],
    );
  }
}
