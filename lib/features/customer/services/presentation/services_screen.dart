import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../shared/models/service_type.dart';
import '../../../../shared/providers/service_providers.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  const ServicesScreen({super.key, this.initialCategory});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  String? _selectedCategory;

  final _categories = const {
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
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
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
                  color: AppColors.textPrimary,
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
                          color: selected ? Colors.white : AppColors.textSecond,
                        ),
                      ),
                      selected: selected,
                      selectedColor: AppColors.bluePrimary,
                      backgroundColor: AppColors.bgSurface,
                      side: BorderSide(
                        color: selected
                            ? AppColors.bluePrimary
                            : AppColors.border,
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
                  );
                },
                loading: () => const TammLoading(),
                error: (e, _) => Center(child: Text('$e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
