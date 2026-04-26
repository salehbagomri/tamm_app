import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/product_specs.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_shimmer.dart';
import '../../../../shared/providers/product_providers.dart';
import '../../../../shared/models/product.dart';
import '../../../../shared/providers/order_providers.dart';
import '../../../../shared/models/cart_item.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/auth_guard.dart';
import 'buy_install_sheet.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: TammAppBar(
        title: 'تفاصيل المنتج',
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final count = ref.watch(cartCountProvider);
              return Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: IconButton(
                  icon: Badge(
                    isLabelVisible: count > 0,
                    label: Text('$count'),
                    backgroundColor: AppColors.error,
                    child: const Icon(Icons.shopping_cart_outlined, color: AppColors.textPrimary),
                  ),
                  onPressed: () => context.push('/customer/cart'),
                  tooltip: 'السلة',
                ),
              );
            },
          ),
        ],
      ),
      body: productAsync.when(
        data: (p) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 300,
                    width: double.infinity,
                    color: AppColors.bgSurface2,
                    child: p.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: p.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => TammShimmer(
                              width: double.infinity,
                              height: double.infinity,
                              borderRadius: BorderRadius.circular(0),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.image,
                              size: 80,
                              color: AppColors.textFaint,
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.image,
                              size: 80,
                              color: AppColors.textFaint,
                            ),
                          ),
                  ),
                  if (p.isFeatured && !p.hasDiscount)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'مميز ⭐',
                          style: GoogleFonts.harmattan(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  if (p.hasDiscount)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'عرض خاص: خصم ${p.discountPercentage}% 🏷️',
                          style: GoogleFonts.harmattan(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: AppSpacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    if (p.brand != null)
                      Text(
                        p.brand!,
                        style: GoogleFonts.harmattan(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecond,
                        ),
                      ),
                    Text(
                      p.name,
                      style: GoogleFonts.harmattan(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          p.price != null ? '${p.price!.toInt()} ر.س' : 'السعر غير محدد',
                          style: GoogleFonts.harmattan(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blueSky,
                            height: 1,
                          ),
                        ),
                        if (p.hasDiscount) ...[
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${p.oldPrice!.toInt()}',
                              style: GoogleFonts.harmattan(
                                fontSize: 18,
                                color: AppColors.textSecond,
                                decoration: TextDecoration.lineThrough,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (p.description != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        'وصف المنتج',
                        style: GoogleFonts.harmattan(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.description!,
                        style: GoogleFonts.harmattan(
                          fontSize: 16,
                          color: AppColors.textSecond,
                          height: 1.6,
                        ),
                      ),
                    ],
                    if (p.specs.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'المواصفات التقنية',
                        style: GoogleFonts.harmattan(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: AppSpacing.radius,
                          border: Border.all(color: AppColors.border),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Column(
                          children: p.specs.entries.toList().asMap().entries.map((entry) {
                            final index = entry.key;
                            final e = entry.value;
                            final isLast = index == p.specs.length - 1;
                            final isEven = index % 2 == 0;
                            final specName = specsTranslation[e.key] ?? e.key;
                            final icon = specsIcons[e.key] ?? Icons.info_outline;

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isEven ? AppColors.bgSurface : AppColors.bgSurface2,
                                border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
                              ),
                              child: Row(
                                children: [
                                  Icon(icon, size: 20, color: AppColors.bluePrimary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      specName,
                                      style: GoogleFonts.harmattan(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecond,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      '${e.value}',
                                      style: GoogleFonts.harmattan(
                                        fontSize: 16,
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.start,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    if (p.price != null)
                      TammButton(
                        label: p.requiresInstallation ? 'اشترِ وركّب / أضف للسلة' : AppStrings.addToCart,
                        icon: Icons.shopping_cart_outlined,
                        onPressed: () => _addToCart(context, ref, p),
                      )
                    else
                      TammButton(
                        label: 'تواصل معنا للسعر',
                        icon: Icons.chat_outlined,
                        type: TammButtonType.secondary,
                        onPressed: () => context.push('/customer/services'),
                      ),
                    const SizedBox(height: 40),
                    // Related Products Section
                    _RelatedProducts(currentProductId: p.id, category: p.category),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const TammLoading(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  Future<void> _addToCart(BuildContext context, WidgetRef ref, Product p) async {
    if (!await requireAuth(context, ref)) return;

    bool wantsInstallation = false;
    if (p.requiresInstallation) {
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
      await cartNotifier.addItem(CartItem(
        product: p,
        includeInstallation: wantsInstallation,
      ));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('تم الإضافة: ${p.name}', style: GoogleFonts.harmattan()),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'عرض السلة',
              textColor: Colors.white,
              onPressed: () {
                ref.read(appRouterProvider).push('/customer/cart');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذرت الإضافة للسلة: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

class _RelatedProducts extends ConsumerWidget {
  final String currentProductId;
  final String category;

  const _RelatedProducts({required this.currentProductId, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We use productsProvider with category to get related items
    final relatedAsync = ref.watch(productsProvider(category));

    return relatedAsync.when(
      data: (products) {
        // Filter out the current product and take top 4
        final related = products.where((p) => p.id != currentProductId).take(4).toList();
        
        if (related.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'منتجات مشابهة',
              style: GoogleFonts.harmattan(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: related.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final rp = related[i];
                  return GestureDetector(
                    onTap: () => context.push('/customer/product/${rp.id}'),
                    child: Container(
                      width: 150,
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: AppSpacing.radius,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                color: AppColors.bgSurface2,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                              ),
                              child: rp.imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                                      child: CachedNetworkImage(
                                        imageUrl: rp.imageUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => TammShimmer(
                                          width: double.infinity,
                                          height: double.infinity,
                                          borderRadius: BorderRadius.circular(0),
                                        ),
                                        errorWidget: (context, url, err) => const Icon(Icons.image, color: AppColors.textFaint),
                                      ),
                                    )
                                  : const Center(child: Icon(Icons.image, color: AppColors.textFaint)),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rp.name,
                                    style: GoogleFonts.harmattan(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Text(
                                        rp.price != null ? '${rp.price!.toInt()}' : 'غير محدد',
                                        style: GoogleFonts.harmattan(
                                          fontSize: 14,
                                          color: AppColors.blueSky,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (rp.price != null)
                                        Text(
                                          ' ر.س',
                                          style: GoogleFonts.harmattan(fontSize: 10, color: AppColors.blueSky),
                                        ),
                                    ],
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
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

