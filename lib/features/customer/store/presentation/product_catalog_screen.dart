import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/tamm_shimmer.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../shared/models/product.dart';
import '../../../../shared/providers/product_providers.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

/// نوع الفلتر المستخدم عند الفتح من الشاشة الرئيسية
enum CatalogFilter { bestSellers, deals }

class ProductCatalogScreen extends ConsumerWidget {
  final CatalogFilter filter;

  const ProductCatalogScreen({super.key, required this.filter});

  String get _title {
    switch (filter) {
      case CatalogFilter.bestSellers:
        return 'الأكثر طلباً 🔥';
      case CatalogFilter.deals:
        return 'عروض وأسعار مميزة 🏷️';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = switch (filter) {
      CatalogFilter.bestSellers => ref.watch(featuredProductsProvider),
      CatalogFilter.deals => ref.watch(dealsProvider),
    };

    final provider = switch (filter) {
      CatalogFilter.bestSellers => featuredProductsProvider,
      CatalogFilter.deals => dealsProvider,
    };

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.colors.textPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _title,
          style: AppTextStyles.sectionTitle(context.colors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.shopping_cart_outlined,
              color: context.colors.textPrimary,
            ),
            onPressed: () => context.push('/customer/cart'),
            tooltip: 'السلة',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: context.colors.bluePrimary,
          backgroundColor: context.colors.bgSurface,
          onRefresh: () async {
            ref.invalidate(provider);
            await ref.read(allProductsProvider.future);
          },
          child: productsAsync.when(
            loading: () => const TammLoading(),
            error: (e, _) => ErrorStateWidget(
              message: e is AppException
                  ? e.message
                  : 'حدث خطأ في تحميل المنتجات',
              onRetry: () => ref.invalidate(provider),
            ),
            data: (products) {
              if (products.isEmpty) {
                return ListView(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                    const TammEmptyState(
                      icon: Icons.inventory_2_outlined,
                      message: 'لا توجد منتجات في هذا القسم حالياً',
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        '${products.length} منتج',
                        style: AppTextStyles.bodySmall(
                          context.colors.textSecond,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: Responsive.gridColumns(context),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: Responsive.isDesktop(context)
                            ? 0.75
                            : 0.62,
                      ),
                      itemCount: products.length,
                      itemBuilder: (_, i) {
                        final p = products[i];
                        return _ProductCard(product: p);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product;
    return GestureDetector(
      onTap: () => context.push('/customer/product/${p.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.bgSurface,
          borderRadius: AppSpacing.radius,
          border: Border.all(color: context.colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // — صورة المنتج
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.colors.bgSurface2,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(11),
                      ),
                    ),
                    child: p.imageUrl != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(11),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: p.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => TammShimmer(
                                width: double.infinity,
                                height: double.infinity,
                                borderRadius: BorderRadius.circular(0),
                              ),
                              errorWidget: (_, __, ___) => Icon(
                                Icons.image_outlined,
                                color: context.colors.textFaint,
                                size: 40,
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: context.colors.textFaint,
                              size: 40,
                            ),
                          ),
                  ),
                  // شارة العروض
                  if (p.hasDiscount)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.error,
                          borderRadius: AppSpacing.radiusXs,
                        ),
                        child: Text(
                          '-${p.discountPercentage}%',
                          style: AppTextStyles.body(context.colors.textPrimary),
                        ),
                      ),
                    ),
                  // شارة الأكثر طلباً
                  if (p.isFeatured && !p.hasDiscount)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.warning,
                          borderRadius: AppSpacing.radiusXs,
                        ),
                        child: Text(
                          'مميز ⭐',
                          style: AppTextStyles.body(context.colors.textPrimary),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // — تفاصيل المنتج
            Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: AppTextStyles.body(context.colors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (p.price != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${p.price!.toInt()} ر.س',
                            style: AppTextStyles.bodySmall(
                              p.hasDiscount
                                  ? context.colors.error
                                  : context.colors.blueSky,
                            ).copyWith(fontWeight: AppTextStyles.bold),
                          ),
                          if (p.hasDiscount && p.oldPrice != null) ...[
                            AppSpacing.hGapXs,
                            Text(
                              '${p.oldPrice!.toInt()} ر.س',
                              style: AppTextStyles.caption(
                                context.colors.textFaint,
                              ).copyWith(decoration: TextDecoration.lineThrough),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
            ),
          ],
        ),
      ),
    );
  }
}
