import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
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
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء تفعيل خدمات الموقع.')),
        );
        setState(() => _isLoadingLocation = false);
        return;
      }

      permission = await Geolocator.checkPermission();
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
          const SnackBar(content: Text('إذن الوصول للموقع مرفوض نهائياً. تم التعيين كموقع افتراضي.')),
        );
        setState(() {
          _lat = 24.7136;
          _lng = 46.6753;
          _addressController.text = 'موقع افتراضي (الرياض)';
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _addressController.text = 'موقعي الحالي (Lat: ${_lat!.toStringAsFixed(2)}, Lng: ${_lng!.toStringAsFixed(2)})';
        _isLoadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء جلب الموقع: $e')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceAsync = ref.watch(serviceDetailProvider(widget.serviceTypeId));

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
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
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 150, // To give space for sticky summary
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Service Info
                Text(
                  'التفاصيل الأساسية',
                  style: GoogleFonts.harmattan(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TammCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.bluePrimary.withValues(alpha: 0.1),
                          borderRadius: AppSpacing.radiusSm,
                        ),
                        child: Icon(
                          service.category.contains('ac_') ? Icons.ac_unit : 
                          service.category.contains('solar') ? Icons.solar_power : Icons.miscellaneous_services,
                          color: AppColors.bluePrimary,
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
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              service.basePrice != null 
                                  ? '${service.basePrice!.toInt()} ر.س' 
                                  : 'يُحدد لاحقاً',
                              style: GoogleFonts.harmattan(
                                fontSize: 16,
                                color: AppColors.blueSky,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 2. Location Section
                Text(
                  'حدد الموقع',
                  style: GoogleFonts.harmattan(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: AppSpacing.radiusLg,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      TammButton(
                        label: 'اختر موقعي الحالي (GPS)',
                        icon: Icons.my_location,
                        type: TammButtonType.secondary,
                        isLoading: _isLoadingLocation,
                        onPressed: _pickLocation,
                      ),
                      const SizedBox(height: 16),
                      TammTextField(
                        label: 'أو اكتب العنوان بالتفصيل',
                        hint: 'المدينة، الحي، الشارع، رقم المبنى...',
                        controller: _addressController,
                        onChanged: (val) => setState((){}), // triggers rebuild for validation
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 3. Appointment Section
                Text(
                  'حدد الموعد',
                  style: GoogleFonts.harmattan(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                if (_selectedDate != null && _selectedPeriod != null) ...[
                  AppointmentDisplayCard(
                    date: _selectedDate!,
                    period: _selectedPeriod!,
                    hour: _selectedHour,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedDate = null;
                          _selectedPeriod = null;
                          _selectedHour = null;
                        });
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: Text(
                        'تعديل الموعد',
                        style: GoogleFonts.harmattan(fontSize: 16),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: AppSpacing.radiusLg,
                      border: Border.all(color: AppColors.border),
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
                const SizedBox(height: 32),

                // 4. Notes Section
                Text(
                  'أضف ملاحظات (اختياري)',
                  style: GoogleFonts.harmattan(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
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

        // 5. Sticky Summary & Submit Button
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
                color: AppColors.bgSurface,
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  top: 8,
                ),
                child: TammButton(
                  label: 'تأكيد الحجز',
                  isLoading: _isSubmitting,
                  onPressed: () => _submitOrder(service),
                ),
              ),
            ],
          )
        else
          Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              top: 16,
            ),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: const Border(top: BorderSide(color: AppColors.border)),
            ),
            child: TammButton(
              label: 'أكمل البيانات المطلوبة لحجز الخدمة',
              type: TammButtonType.secondary,
              onPressed: () {},
            ),
          ),
      ],
    );
  }
}
