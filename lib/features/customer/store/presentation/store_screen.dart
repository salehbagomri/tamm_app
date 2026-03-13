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
import '../../../../shared/providers/order_providers.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  String? _selectedCategory;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final _categories = const {
    null: 'الكل',
    'ac': 'مكيفات',
    'solar_panel': 'ألواح شمسية',
    'solar_battery': 'بطاريات',
    'solar_inverter': 'إنفرتر',
    'accessory': 'إكسسوارات',
  };

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.store,
                    style: GoogleFonts.harmattan(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final count = ref.watch(cartCountProvider);
                      return IconButton(
                        icon: Badge(
                          isLabelVisible: count > 0,
                          label: Text('$count'),
                          backgroundColor: AppColors.error,
                          child: const Icon(Icons.shopping_cart_outlined, color: AppColors.textPrimary),
                        ),
                        onPressed: () => context.push('/customer/cart'),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                style: GoogleFonts.harmattan(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'ابحث عن منتج أو ماركة...',
                  hintStyle: GoogleFonts.harmattan(color: AppColors.textSecond),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecond),
                  filled: true,
                  fillColor: AppColors.bgSurface,
                  border: OutlineInputBorder(
                    borderRadius: AppSpacing.radius,
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppSpacing.radius,
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppSpacing.radius,
                    borderSide: const BorderSide(color: AppColors.bluePrimary),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textSecond),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              ),
            ),
            const SizedBox(height: 16),
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
                  var filtered = products;
                  if (_searchQuery.isNotEmpty) {
                    filtered = products.where((p) {
                      final nameMatch = p.name.toLowerCase().contains(_searchQuery);
                      final brandMatch = p.brand?.toLowerCase().contains(_searchQuery) ?? false;
                      return nameMatch || brandMatch;
                    }).toList();
                  }

                  if (filtered.isEmpty) {
                    return TammEmptyState(
                      icon: Icons.search_off,
                      message: _searchQuery.isNotEmpty ? 'لا توجد نتائج للبحث' : 'لا توجد منتجات',
                    );
                  }
                  return GridView.builder(
                    padding: AppSpacing.pagePadding,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final p = filtered[i];
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
                                  decoration: const BoxDecoration(
                                    color: AppColors.bgSurface2,
                                    borderRadius: BorderRadius.vertical(
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
