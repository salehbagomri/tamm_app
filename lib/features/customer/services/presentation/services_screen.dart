import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../shared/providers/service_providers.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  IconData _getIcon(String? name) => switch (name) {
    'ac_unit' => Icons.ac_unit,
    'build' => Icons.build,
    'handyman' => Icons.handyman,
    'cleaning_services' => Icons.cleaning_services,
    'solar_power' => Icons.solar_power,
    'support_agent' => Icons.support_agent,
    _ => Icons.miscellaneous_services,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(serviceTypesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الخدمات',
                style: GoogleFonts.harmattan(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: servicesAsync.when(
                  data: (services) => ListView.separated(
                    itemCount: services.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final s = services[i];
                      return TammCard(
                        onTap: () =>
                            context.push('/customer/service-request/${s.id}'),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.bluePrimary.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: AppSpacing.radiusSm,
                              ),
                              child: Icon(
                                _getIcon(s.iconName),
                                color: AppColors.bluePrimary,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    style: GoogleFonts.harmattan(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (s.description != null)
                                    Text(
                                      s.description!,
                                      style: GoogleFonts.harmattan(
                                        fontSize: 13,
                                        color: AppColors.textSecond,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              s.basePrice != null
                                  ? '${s.basePrice!.toInt()} ريال'
                                  : 'عرض سعر',
                              style: GoogleFonts.harmattan(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.blueSky,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  loading: () => const TammLoading(),
                  error: (e, _) => Center(child: Text('$e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
