import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_shimmer.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/responsive_wrapper.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/models/cart_item.dart';
import '../../../../shared/providers/product_providers.dart';
import '../../../../shared/providers/order_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import 'buy_install_sheet.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});
  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  final _categories = {
    null: 'الكل',
    'deals': 'العروض',
    'ac': 'مكيفات',
    'solar_panel': 'ألواح شمسية',
    'solar_battery': 'بطاريات',
    'solar_inverter': 'إنفرتر',
    'accessory': 'إكسسوارات',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final query = ref.read(storeFilterProvider).searchQuery;
      if (query.isNotEmpty) _searchCtrl.text = query;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.bgSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const _FilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProductsAsync = ref.watch(storeFilteredProductsProvider);
    final categoryCounts = ref.watch(categoryCountsProvider);
    final filter = ref.watch(storeFilterProvider);

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      body: SafeArea(
        child: ResponsiveWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.store, style: GoogleFonts.harmattan(fontSize: 26, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
                    Consumer(
                      builder: (context, ref, child) {
                        final count = ref.watch(cartCountProvider);
                        return IconButton(
                          icon: Badge(
                            isLabelVisible: count > 0,
                            label: Text('$count'),
                            backgroundColor: context.colors.error,
                            child: Icon(Icons.shopping_cart_outlined, color: context.colors.textPrimary),
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
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        style: GoogleFonts.harmattan(color: context.colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'ابحث عن منتج أو ماركة...',
                          hintStyle: GoogleFonts.harmattan(color: context.colors.textSecond),
                          prefixIcon: Icon(Icons.search, color: context.colors.textSecond),
                          filled: true,
                          fillColor: context.colors.bgSurface,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(borderRadius: AppSpacing.radius, borderSide: BorderSide(color: context.colors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: AppSpacing.radius, borderSide: BorderSide(color: context.colors.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: AppSpacing.radius, borderSide: BorderSide(color: context.colors.bluePrimary)),
                          suffixIcon: filter.searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: context.colors.textSecond),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    ref.read(storeFilterProvider.notifier).update((s) => s.copyWith(searchQuery: ''));
                                  },
                                )
                              : null,
                        ),
                        onChanged: (val) => ref.read(storeFilterProvider.notifier).update((s) => s.copyWith(searchQuery: val)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: context.colors.bgSurface,
                        borderRadius: AppSpacing.radius,
                        border: Border.all(
                          color: (filter.sort != ProductSort.none || filter.dealsOnly || filter.featuredOnly)
                              ? context.colors.bluePrimary
                              : context.colors.border,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.tune,
                          color: (filter.sort != ProductSort.none || filter.dealsOnly || filter.featuredOnly)
                              ? context.colors.bluePrimary
                              : context.colors.textSecond,
                        ),
                        onPressed: _showFilterSheet,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _categories.entries.map((e) {
                    final isSelected = filter.category == e.key;
                    final count = categoryCounts[e.key] ?? 0;
                    if (e.key != null && count == 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text('${e.value} ($count)', style: GoogleFonts.harmattan(fontSize: 14, color: isSelected ? Colors.white : context.colors.textSecond)),
                        selected: isSelected,
                        selectedColor: context.colors.bluePrimary,
                        backgroundColor: context.colors.bgSurface,
                        side: BorderSide(color: isSelected ? context.colors.bluePrimary : context.colors.border),
                        onSelected: (_) => ref.read(storeFilterProvider.notifier).update((s) => s.copyWith(category: e.key, clearCategory: e.key == null)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: filteredProductsAsync.whenData((products) =>
                  Text('${products.length} نتيجة', style: GoogleFonts.harmattan(fontSize: 14, color: context.colors.textSecond))
                ).valueOrNull ?? const SizedBox.shrink(),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: context.colors.bluePrimary,
                  backgroundColor: context.colors.bgSurface,
                  onRefresh: () async {
                    ref.invalidate(allProductsProvider);
                    await ref.read(allProductsProvider.future);
                  },
                  child: filteredProductsAsync.when(
                    data: (products) {
                      if (products.isEmpty) {
                        return ListView(children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                          TammEmptyState(
                            icon: Icons.search_off,
                            message: _searchCtrl.text.isNotEmpty ? 'لا توجد نتائج للبحث' : 'لا توجد منتجات',
                          ),
                        ]);
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                        physics: const AlwaysScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: Responsive.gridColumns(context),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: Responsive.isDesktop(context) ? 0.75 : 0.62,
                        ),
                        itemCount: products.length,
                        itemBuilder: (_, i) {
                          final p = products[i];
                          return GestureDetector(
                            onTap: () => context.push('/customer/product/${p.id}'),
                            child: Container(
                              decoration: BoxDecoration(
                                color: context.colors.bgSurface,
                                borderRadius: AppSpacing.radius,
                                border: Border.all(color: context.colors.border),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))],
                              ),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Expanded(flex: 5, child: Stack(children: [
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(color: context.colors.bgSurface2, borderRadius: const BorderRadius.vertical(top: Radius.circular(11))),
                                    child: p.imageUrl != null
                                        ? ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                                            child: CachedNetworkImage(
                                              imageUrl: p.imageUrl!, fit: BoxFit.cover,
                                              placeholder: (context, url) => TammShimmer(width: double.infinity, height: double.infinity, borderRadius: BorderRadius.circular(0)),
                                              errorWidget: (context, url, error) => Icon(Icons.image, color: context.colors.textFaint, size: 40),
                                            ))
                                        : Center(child: Icon(Icons.image, color: context.colors.textFaint, size: 40)),
                                  ),
                                  if (p.isFeatured && !p.hasDiscount)
                                    Positioned(top: 8, right: 8, child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: context.colors.warning, borderRadius: BorderRadius.circular(4)),
                                      child: Text('مميز ⭐', style: GoogleFonts.harmattan(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                                    )),
                                  if (p.hasDiscount)
                                    Positioned(top: 8, right: 8, child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: context.colors.error, borderRadius: BorderRadius.circular(4)),
                                      child: Text('خصم ${p.discountPercentage}% 🏷️', style: GoogleFonts.harmattan(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                                    )),
                                ])),
                                Expanded(flex: 4, child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    if (p.brand != null) Text(p.brand!, style: GoogleFonts.harmattan(fontSize: 12, color: context.colors.textSecond, height: 1), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text(p.name, style: GoogleFonts.harmattan(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textPrimary, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const Spacer(),
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        if (p.hasDiscount) Text('${p.oldPrice!.toInt()}', style: GoogleFonts.harmattan(fontSize: 12, color: context.colors.textSecond, decoration: TextDecoration.lineThrough, height: 1)),
                                        Text(p.price != null ? '${p.price!.toInt()} ر.س' : 'غير محدد', style: GoogleFonts.harmattan(fontSize: 16, color: context.colors.blueSky, fontWeight: FontWeight.w700, height: 1.1)),
                                      ])),
                                      if (p.price != null)
                                        InkWell(
                                          onTap: () => _quickAddToCart(context, p),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(color: context.colors.bluePrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                            child: Icon(Icons.add_shopping_cart, size: 20, color: context.colors.blueSky),
                                          ),
                                        ),
                                    ]),
                                  ]),
                                )),
                              ]),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const TammLoading(),
                    error: (e, _) => ListView(children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                      ErrorStateWidget(
                        message: e is AppException ? e.message : 'حدث خطأ في تحميل المنتجات',
                        onRetry: () => ref.invalidate(allProductsProvider),
                      ),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _quickAddToCart(BuildContext context, dynamic p) async {
    if (!await requireAuth(context, ref)) return;
    bool wantsInstallation = false;
    if (p.requiresInstallation) {
      if (!context.mounted) return;
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const BuyInstallSheet(),
      );
      if (result == null) return;
      wantsInstallation = result;
    }
    try {
      final cartNotifier = ref.read(cartProvider.notifier);
      await cartNotifier.addItem(CartItem(product: p, includeInstallation: wantsInstallation));
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('تم الإضافة: ${p.name}', style: GoogleFonts.harmattan()),
          ]),
          backgroundColor: context.colors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'عرض السلة',
            textColor: Colors.white,
            onPressed: () => ref.read(appRouterProvider).push('/customer/cart'),
          ),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is AppException ? e.message : 'تعذرت الإضافة للسلة', style: GoogleFonts.harmattan(fontSize: 15)),
          backgroundColor: context.colors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(storeFilterProvider);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: context.colors.bgSurface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('خيارات الفلترة', style: GoogleFonts.harmattan(fontSize: 22, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
              IconButton(icon: Icon(Icons.close, color: context.colors.textSecond), onPressed: () => Navigator.of(context).pop()),
            ]),
            const SizedBox(height: 16),
            Text('الترتيب حسب', style: GoogleFonts.harmattan(fontSize: 16, fontWeight: FontWeight.w600, color: context.colors.textSecond)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _buildSortChip(context, ref, filter, 'الافتراضي', ProductSort.none),
              _buildSortChip(context, ref, filter, 'الأقل سعراً', ProductSort.priceAsc),
              _buildSortChip(context, ref, filter, 'الأعلى سعراً', ProductSort.priceDesc),
            ]),
            const SizedBox(height: 24),
            Text('إظهار المنتجات التي تحتوي على', style: GoogleFonts.harmattan(fontSize: 16, fontWeight: FontWeight.w600, color: context.colors.textSecond)),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: Text('عروض وتخفيضات 🏷️', style: GoogleFonts.harmattan(color: context.colors.textPrimary)),
              value: filter.dealsOnly, activeColor: context.colors.bluePrimary, contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading,
              onChanged: (val) => ref.read(storeFilterProvider.notifier).update((s) => s.copyWith(dealsOnly: val)),
            ),
            CheckboxListTile(
              title: Text('منتجات مميزة ⭐', style: GoogleFonts.harmattan(color: context.colors.textPrimary)),
              value: filter.featuredOnly, activeColor: context.colors.bluePrimary, contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading,
              onChanged: (val) => ref.read(storeFilterProvider.notifier).update((s) => s.copyWith(featuredOnly: val)),
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: TammButton(label: 'تطبيق', onPressed: () => Navigator.of(context).pop())),
          ]),
        ),
      ),
    );
  }

  Widget _buildSortChip(BuildContext context, WidgetRef ref, StoreFilterState filter, String label, ProductSort sort) {
    final isSelected = filter.sort == sort;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.harmattan(color: isSelected ? Colors.white : context.colors.textSecond)),
      selected: isSelected,
      selectedColor: context.colors.bluePrimary,
      backgroundColor: context.colors.bgSurface2,
      side: BorderSide(color: isSelected ? context.colors.bluePrimary : context.colors.border),
      onSelected: (_) => ref.read(storeFilterProvider.notifier).update((s) => s.copyWith(sort: sort)),
    );
  }
}
