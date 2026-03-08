import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../shared/providers/product_providers.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  String? _selectedCategory;
  final _categories = const {
    null: 'الكل',
    'ac': 'مكيفات',
    'solar_panel': 'ألواح شمسية',
    'solar_battery': 'بطاريات',
    'solar_inverter': 'إنفرتر',
    'accessory': 'إكسسوارات',
  };

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider(_selectedCategory));

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                AppStrings.store,
                style: GoogleFonts.harmattan(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
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
            const SizedBox(height: 12),
            Expanded(
              child: productsAsync.when(
                data: (products) {
                  if (products.isEmpty)
                    return const TammEmptyState(
                      icon: Icons.shopping_bag_outlined,
                      message: 'لا توجد منتجات',
                    );
                  return GridView.builder(
                    padding: AppSpacing.pagePadding,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: products.length,
                    itemBuilder: (_, i) {
                      final p = products[i];
                      return GestureDetector(
                        onTap: () => context.push('/customer/product/${p.id}'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface,
                            borderRadius: AppSpacing.radius,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.bgSurface2,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                  ),
                                  child: p.imageUrl != null
                                      ? ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(12),
                                              ),
                                          child: Image.network(
                                            p.imageUrl!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Center(
                                          child: Icon(
                                            Icons.image,
                                            color: AppColors.textFaint,
                                            size: 40,
                                          ),
                                        ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: GoogleFonts.harmattan(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Spacer(),
                                      Text(
                                        p.price != null
                                            ? '${p.price!.toInt()} ريال'
                                            : AppStrings.requestQuote,
                                        style: GoogleFonts.harmattan(
                                          fontSize: 15,
                                          color: AppColors.blueSky,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const TammLoading(),
                error: (e, _) =>
                    TammEmptyState(icon: Icons.error_outline, message: '$e'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
