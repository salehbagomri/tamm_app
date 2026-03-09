import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../shared/models/service_type.dart';
import '../../../../shared/providers/manager_providers.dart';

class ManageServicesScreen extends ConsumerWidget {
  const ManageServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(managerServicesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        title: Text(
          'إدارة الخدمات',
          style: GoogleFonts.harmattan(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(managerServicesProvider),
        child: servicesAsync.when(
          data: (services) {
            if (services.isEmpty) {
              return Center(
                child: Text(
                  'لا توجد خدمات مضافة.',
                  style: GoogleFonts.harmattan(
                    fontSize: 20,
                    color: AppColors.textSecond,
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: AppSpacing.pagePadding,
              itemCount: services.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final service = services[index] as ServiceType;
                return TammCard(
                  onTap: () {
                    // Navigate to service form with existing data
                    context.push('/manager/service/form', extra: service);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                                decoration: !service.isActive
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${service.basePrice?.toInt() ?? 0} ريال',
                              style: GoogleFonts.harmattan(
                                fontSize: 16,
                                color: AppColors.bluePrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (service.description != null)
                              Text(
                                service.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.harmattan(
                                  color: AppColors.textSecond,
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Switch(
                            value: service.isActive,
                            activeColor: AppColors.success,
                            onChanged: (val) async {
                              await ref
                                  .read(serviceRepositoryProvider)
                                  .hideServiceType(service.id, val);
                              ref.invalidate(managerServicesProvider);
                            },
                          ),
                          Text(
                            service.isActive ? 'مفعل' : 'مخفي',
                            style: GoogleFonts.harmattan(
                              color: service.isActive
                                  ? AppColors.success
                                  : AppColors.error,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const TammLoading(),
          error: (e, _) => Center(child: Text('خطأ: $e')),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/manager/service/form'),
        backgroundColor: AppColors.bluePrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'إضافة خدمة',
          style: GoogleFonts.harmattan(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
