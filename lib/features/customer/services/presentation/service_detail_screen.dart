import '../../../../core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../shared/models/service_type.dart';
import '../../../../shared/providers/service_providers.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class ServiceDetailScreen extends ConsumerWidget {
  final String serviceTypeId;

  const ServiceDetailScreen({super.key, required this.serviceTypeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We get the specific service from the provider
    final serviceAsync = ref.watch(serviceDetailProvider(serviceTypeId));

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: const TammAppBar(title: 'تفاصيل الخدمة'),
      body: serviceAsync.when(
        data: (service) => _buildBody(context, ref, service),
        loading: () => const TammLoading(),
        error: (err, stack) => ErrorStateWidget(
          message: err is AppException
              ? err.message
              : 'حدث خطأ في جلب تفاصيل الخدمة',
          onRetry: () => ref.invalidate(serviceDetailProvider(serviceTypeId)),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ServiceType service) {
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
                      color: context.colors.bluePrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconForCategory(service.category),
                      size: 50,
                      color: context.colors.bluePrimary,
                    ),
                  ),
                ),
                AppSpacing.gapLg,

                // Name and Price
                Text(
                  service.name,
                  style: AppTextStyles.h3(context.colors.textPrimary),
                ),
                AppSpacing.gapSm,
                Row(
                  children: [
                    Text(
                      service.isQuoteBased || service.basePrice == null
                          ? 'تتطلب عرض سعر'
                          : '${service.basePrice!.toInt()} ر.س',
                      style: AppTextStyles.body(context.colors.textPrimary),
                    ),
                    if (service.estimatedDuration != null) ...[
                      const Spacer(),
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: context.colors.textSecond,
                      ),
                      AppSpacing.hGapXs,
                      Text(
                        service.estimatedDuration!,
                        style: AppTextStyles.bodySmall(
                          context.colors.textSecond,
                        ),
                      ),
                    ],
                  ],
                ),
                AppSpacing.gapMd,

                // Description
                if (service.description != null &&
                    service.description!.isNotEmpty) ...[
                  Text(
                    'وصف الخدمة',
                    style: AppTextStyles.cardTitle(context.colors.textPrimary),
                  ),
                  AppSpacing.gapSm,
                  Text(
                    service.description!,
                    style: AppTextStyles.body(context.colors.textSecond),
                  ),
                  AppSpacing.gapLg,
                ],

                // What's included
                if (service.includes.isNotEmpty) ...[
                  Text(
                    'ماذا تشمل الخدمة؟',
                    style: AppTextStyles.cardTitle(context.colors.textPrimary),
                  ),
                  AppSpacing.gapSm,
                  Container(
                    padding: AppSpacing.cardPadding,
                    decoration: BoxDecoration(
                      color: context.colors.bgSurface,
                      borderRadius: AppSpacing.radiusLg,
                      border: Border.all(color: context.colors.border),
                    ),
                    child: Column(
                      children: service.includes
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 20,
                                    color: context.colors.success,
                                  ),
                                  AppSpacing.hGapSm,
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: AppTextStyles.body(
                                        context.colors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  AppSpacing.gapXl,
                ],
              ],
            ),
          ),
        ),

        // Sticky Bottom Button
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
            label: service.isQuoteBased ? 'اطلب عرض السعر' : 'احجز الخدمة الآن',
            icon: Icons.arrow_forward_rounded,
            onPressed: () async {
              if (!await requireAuth(context, ref)) return;
              if (!context.mounted) return;

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
    if (category.contains('ac_')) return Icons.ac_unit_outlined;
    if (category.contains('solar')) return Icons.solar_power_outlined;
    return Icons.miscellaneous_services_outlined;
  }
}
