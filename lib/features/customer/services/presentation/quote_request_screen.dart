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
import '../../../../shared/providers/service_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/order_providers.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تفعيل خدمات الموقع.')));
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفض إذن الوصول للموقع.')));
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('إذن الوصول للموقع مرفوض نهائياً. تم التعيين كموقع افتراضي.')));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء جلب الموقع: $e')));
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
        total: 0.0, // Since it's a quote, price isn't set yet
        notes: '${_descriptionController.text.trim()}\n\nملاحظات إضافية: ${_notesController.text.trim()}',
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
          }
        ],
      );
      
      ref.invalidate(myOrdersProvider);
      ref.invalidate(allOrdersProvider(null));
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 8),
                Text('تم الإرسال بنجاح'),
              ],
            ),
            content: const Text('لقد استلمنا طلب العرض الخاص بك. سيقوم فريقنا بمراجعته وإرسال تفاصيل السعر قريباً.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  context.push('/customer/order/$orderId'); // Go to order
                },
                child: const Text('تتبع الطلب'),
              ),
              TammButton(
                label: 'الرئيسية',
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  context.go('/customer/home'); // Go to home
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
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
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
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
                    // Service Info
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
                                  'تتطلب الخدمة معاينة أو تقييم لتقديم السعر',
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
                    ),
                    const SizedBox(height: 24),

                    // Description
                    Text(
                      'وصف الاحتياج',
                      style: GoogleFonts.harmattan(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TammTextField(
                      label: 'أشرح تفاصيل الخدمة المطلوبة',
                      hint: 'مثال: أحتاج تركيب 3 مكيفات اسبليت بالدور الأول...',
                      controller: _descriptionController,
                      maxLines: 4,
                      onChanged: (val) => setState((){}),
                    ),
                    const SizedBox(height: 24),

                    // Location
                    Text(
                      'الموقع',
                      style: GoogleFonts.harmattan(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                            hint: 'المدينة، الحي، الشارع...',
                            controller: _addressController,
                            onChanged: (val) => setState((){}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Phone Number
                    Text(
                      'رقم التواصل',
                      style: GoogleFonts.harmattan(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TammTextField(
                      label: 'الرقم المسجل في النظام',
                      hint: '',
                      controller: TextEditingController(text: user?.phone ?? ''),
                      readOnly: true,
                    ),
                    const SizedBox(height: 24),
                    
                    // Notes
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
            
            // Submit Button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                border: const Border(top: BorderSide(color: AppColors.border)),
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
                onPressed: _isFormValid() ? () => _submitQuoteRequest(service) : null,
              ),
            ),
          ],
        ),
        loading: () => const TammLoading(),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('حدث خطأ', style: GoogleFonts.harmattan(fontSize: 18)),
              TammButton(
                label: 'رجوع',
                onPressed: () => context.pop(),
              )
            ],
          ),
        ),
      ),
    );
  }
}
