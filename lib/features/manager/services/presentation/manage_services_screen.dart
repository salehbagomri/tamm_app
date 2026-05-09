import '../../../../core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../shared/models/service_type.dart';
import '../../../../shared/providers/manager_providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class ManageServicesScreen extends ConsumerWidget {
  const ManageServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(managerServicesProvider);

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.bgPrimary,
        title: Text(
          'إدارة الخدمات',
          style: AppTextStyles.h3(context.colors.textPrimary),
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
                  style: AppTextStyles.body(context.colors.textPrimary),
                ),
              );
            }
            return ListView.separated(
              padding: AppSpacing.pagePadding,
              itemCount: services.length,
              separatorBuilder: (_, __) => AppSpacing.gapSm2,
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
                              style: AppTextStyles.body(
                                context.colors.textPrimary,
                              ),
                            ),
                            AppSpacing.gapXs,
                            Text(
                              '${service.basePrice?.toInt() ?? 0} ر.س',
                              style: AppTextStyles.body(
                                context.colors.textPrimary,
                              ),
                            ),
                            if (service.description != null)
                              Text(
                                service.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body(
                                  context.colors.textPrimary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Switch(
                            value: service.isActive,
                            activeThumbColor: context.colors.success,
                            onChanged: (val) async {
                              await ref
                                  .read(serviceRepositoryProvider)
                                  .hideServiceType(service.id, val);
                              ref.invalidate(managerServicesProvider);
                            },
                          ),
                          Text(
                            service.isActive ? 'مفعل' : 'مخفي',
                            style: AppTextStyles.body(
                              context.colors.textPrimary,
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
          error: (e, _) => ErrorStateWidget(
            message: e is AppException ? e.message : 'حدث خطأ في تحميل الخدمات',
            onRetry: () => ref.invalidate(managerServicesProvider),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/manager/service/form'),
        backgroundColor: context.colors.bluePrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'إضافة خدمة',
          style: AppTextStyles.body(context.colors.textPrimary),
        ),
      ),
    );
  }
}
