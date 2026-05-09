import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_shimmer.dart';
import '../../../../core/widgets/tamm_button.dart';
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
    'ac_unit' => Icons.ac_unit,
    'build' => Icons.build,
    'handyman' => Icons.handyman,
    'cleaning_services' => Icons.cleaning_services,
    'solar_power' => Icons.solar_power,
    'support_agent' => Icons.support_agent,
    _ => Icons.miscellaneous_services,
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
                  style: GoogleFonts.harmattan(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
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
                          style: GoogleFonts.harmattan(
                            fontSize: 14,
                            color: selected
                                ? Colors.white
                                : context.colors.textSecond,
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
              const SizedBox(height: 8),
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
                      return const TammEmptyState(
                        icon: Icons.miscellaneous_services,
                        message: 'لا توجد خدمات في هذا التصنيف حالياً',
                      );
                    }

                    return ListView.separated(
                      padding: AppSpacing.pagePadding,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final s = filtered[i];
                        return TammCard(
                          onTap: () =>
                              context.push('/customer/service-detail/${s.id}'),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: context.colors.bluePrimary.withValues(
                                    alpha: 0.15,
                                  ),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.name,
                                      style: GoogleFonts.harmattan(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: context.colors.textPrimary,
                                      ),
                                    ),
                                    if (s.description != null)
                                      Text(
                                        s.description!,
                                        style: GoogleFonts.harmattan(
                                          fontSize: 13,
                                          color: context.colors.textSecond,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                s.basePrice != null
                                    ? '${s.basePrice!.toInt()} ر.س'
                                    : 'عرض سعر',
                                style: GoogleFonts.harmattan(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.blueSky,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => ListView.separated(
                    padding: AppSpacing.pagePadding,
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, __) => TammShimmer(
                      height: 80,
                      width: double.infinity,
                      borderRadius: BorderRadius.circular(12),
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
