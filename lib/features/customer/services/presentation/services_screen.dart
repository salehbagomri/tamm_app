import '../../../../core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_shimmer.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../core/widgets/responsive_wrapper.dart';
import '../../../../shared/models/service_type.dart';
import '../../../../shared/providers/service_providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  const ServicesScreen({super.key, this.initialCategory});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  String? _selectedCategory;

  final _categories = {
    null: 'الكل',
    'ac_install': 'تركيب مكيف',
    'ac_repair': 'صيانة مكيف',
    'ac_wash': 'غسيل مكيف',
    'ac_maintenance': 'متابعة دورية',
    'solar_install': 'تركيب طاقة شمسية',
    'solar_maintenance': 'صيانة شمسية',
    'consultation': 'استشارة فنية',
  };

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  IconData _getIcon(String? name) => switch (name) {
    'ac_unit' => Icons.ac_unit_outlined,
    'build' => Icons.build_outlined,
    'handyman' => Icons.handyman_outlined,
    'cleaning_services' => Icons.cleaning_services_outlined,
    'solar_power' => Icons.solar_power_outlined,
    'support_agent' => Icons.support_agent_outlined,
    _ => Icons.miscellaneous_services_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(serviceTypesProvider);

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      body: SafeArea(
        child: ResponsiveWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'الخدمات',
                  style: AppTextStyles.body(context.colors.textPrimary),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _categories.entries.map((e) {
                    final selected = _selectedCategory == e.key;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(
                          e.value,
                          style: AppTextStyles.bodySmall(
                            selected ? Colors.white : context.colors.textSecond,
                          ),
                        ),
                        selected: selected,
                        selectedColor: context.colors.bluePrimary,
                        backgroundColor: context.colors.bgSurface,
                        side: BorderSide(
                          color: selected
                              ? context.colors.bluePrimary
                              : context.colors.border,
                        ),
                        onSelected: (_) =>
                            setState(() => _selectedCategory = e.key),
                      ),
                    );
                  }).toList(),
                ),
              ),
              AppSpacing.gapSm,
              Expanded(
                child: servicesAsync.when(
                  data: (services) {
                    List<ServiceType> filtered = services;
                    if (_selectedCategory != null) {
                      filtered = services
                          .where((s) => s.category == _selectedCategory)
                          .toList();
                    }

                    if (filtered.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(serviceTypesProvider),
                        child: ListView(
                          children: const [
                            TammEmptyState(
                              icon: Icons.miscellaneous_services_outlined,
                              message: 'لا توجد خدمات في هذا التصنيف حالياً',
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(serviceTypesProvider),
                      child: ListView.separated(
                        padding: AppSpacing.pagePadding,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final s = filtered[i];
                          return TammCard(
                            onTap: () => context.push(
                              '/customer/service-detail/${s.id}',
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: context.colors.bluePrimary
                                        .withValues(alpha: 0.15),
                                    borderRadius: AppSpacing.radiusSm,
                                  ),
                                  child: Icon(
                                    _getIcon(s.iconName),
                                    color: context.colors.bluePrimary,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.name,
                                        style:
                                            AppTextStyles.body(
                                              context.colors.textPrimary,
                                            ).copyWith(
                                              fontWeight: AppTextStyles.bold,
                                            ),
                                      ),
                                      if (s.description != null)
                                        Text(
                                          s.description!,
                                          style: AppTextStyles.body(
                                            context.colors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                s.isQuoteBased || s.basePrice == null
                                    ? _QuotePriceBadge()
                                    : Text(
                                        '${s.basePrice!.toInt()} ر.س',
                                        style:
                                            AppTextStyles.bodySmall(
                                              context.colors.blueSky,
                                            ).copyWith(
                                              fontWeight: AppTextStyles.bold,
                                            ),
                                      ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => ListView.separated(
                    padding: AppSpacing.pagePadding,
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, __) => const TammShimmer(
                      height: 80,
                      width: double.infinity,
                      borderRadius: AppSpacing.radius,
                    ),
                  ),
                  error: (e, _) => ErrorStateWidget(
                    message: e is AppException
                        ? e.message
                        : 'حدث خطأ في تحميل الخدمات',
                    onRetry: () => ref.invalidate(serviceTypesProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuotePriceBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.warning.withValues(alpha: 0.12),
        borderRadius: AppSpacing.radiusFull,
        border: Border.all(
          color: context.colors.warning.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        'سعر حسب الطلب',
        style: AppTextStyles.caption(
          context.colors.warning,
        ).copyWith(fontWeight: AppTextStyles.semiBold),
      ),
    );
  }
}
