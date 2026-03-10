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

class ServiceRequestScreen extends ConsumerStatefulWidget {
  final String serviceTypeId;
  const ServiceRequestScreen({super.key, required this.serviceTypeId});
  @override
  ConsumerState<ServiceRequestScreen> createState() =>
      _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends ConsumerState<ServiceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final String _timeSlot = 'صباحاً';
  bool _loading = false;
  DateTime _date = DateTime.now().add(const Duration(days: 1));

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
      await ref
          .read(orderRepositoryProvider)
          .createOrder(
            orderType: 'service',
            address: _addressCtrl.text,
            total: 0,
            preferredDate: _date,
            timeSlot: _timeSlot,
            notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
            latitude: _latitude,
            longitude: _longitude,
            items: [
              {
                'item_type': 'service',
                'service_type_id': widget.serviceTypeId,
                'quantity': 1,
                'unit_price': 0,
                'total_price': 0,
              },
            ],
          );
      if (mounted) context.go('/customer/service-success');
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
      appBar: const TammAppBar(title: 'طلب خدمة'),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
                hint: 'العنوان بالتفصيل (الحي، الشارع، رقم المبنى)',
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
                        initialDate: _date,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (d != null) setState(() => _date = d);
                    },
                    child: Text(
                      '${_date.day}/${_date.month}/${_date.year}',
                      style: GoogleFonts.harmattan(color: AppColors.blueLight),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TammTextField(
                label: AppStrings.notes,
                hint: 'وصف المشكلة أو الطلب',
                controller: _notesCtrl,
                maxLines: 4,
              ),
              const SizedBox(height: 32),
              TammButton(
                label: 'إرسال الطلب',
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
