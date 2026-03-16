import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../shared/models/service_type.dart';
import '../../../../shared/providers/service_providers.dart';

class ServiceDetailScreen extends ConsumerWidget {
  final String serviceTypeId;
  
  const ServiceDetailScreen({super.key, required this.serviceTypeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We get the specific service from the provider
    final serviceAsync = ref.watch(serviceDetailProvider(serviceTypeId));

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: const TammAppBar(title: 'تفاصيل الخدمة'),
      body: serviceAsync.when(
        data: (service) => _buildBody(context, service),
        loading: () => const TammLoading(),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'حدث خطأ في جلب تفاصيل الخدمة',
                style: GoogleFonts.harmattan(
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TammButton(
                label: 'حاول مجدداً',
                onPressed: () => ref.invalidate(serviceDetailProvider(serviceTypeId)),
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
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Image/Icon
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.bluePrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconForCategory(service.category),
                      size: 50,
                      color: AppColors.bluePrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Name and Price
                Text(
                  service.name,
                  style: GoogleFonts.harmattan(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      service.isQuoteBased || service.basePrice == null
                          ? 'تتطلب عرض سعر'
                          : '${service.basePrice!.toInt()} ر.س',
                      style: GoogleFonts.harmattan(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blueSky,
                      ),
                    ),
                    if (service.estimatedDuration != null) ...[
                      const Spacer(),
                      const Icon(Icons.timer_outlined, size: 16, color: AppColors.textSecond),
                      const SizedBox(width: 4),
                      Text(
                        service.estimatedDuration!,
                        style: GoogleFonts.harmattan(
                          fontSize: 14,
                          color: AppColors.textSecond,
                        ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                if (service.description != null && service.description!.isNotEmpty) ...[
                  Text(
                    'وصف الخدمة',
                    style: GoogleFonts.harmattan(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service.description!,
                    style: GoogleFonts.harmattan(
                      fontSize: 16,
                      color: AppColors.textSecond,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // What's included
                if (service.includes.isNotEmpty) ...[
                  Text(
                    'ماذا تشمل الخدمة؟',
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
                      children: service.includes.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle, size: 20, color: AppColors.success),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item,
                                style: GoogleFonts.harmattan(
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          ),
        ),

        // Sticky Bottom Button
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            border: const Border(
              top: BorderSide(color: AppColors.border),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: TammButton(
            label: service.isQuoteBased ? 'اطلب عرض السعر' : 'احجز الخدمة الآن',
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              if (service.isQuoteBased) {
                context.push('/customer/quote-request/${service.id}');
              } else {
                context.push('/customer/service-request/${service.id}');
              }
            },
          ),
        ),
      ],
    );
  }

  IconData _getIconForCategory(String category) {
    if (category.contains('ac_')) return Icons.ac_unit;
    if (category.contains('solar')) return Icons.solar_power;
    return Icons.miscellaneous_services;
  }
}
