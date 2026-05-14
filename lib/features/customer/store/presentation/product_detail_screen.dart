import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
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
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import 'buy_install_sheet.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
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
                    backgroundColor: context.colors.error,
                    child: Icon(
                      Icons.shopping_cart_outlined,
                      color: context.colors.textPrimary,
                    ),
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
        data: (p) => _buildBody(context, ref, p),
        loading: () => const TammLoading(),
        error: (e, _) => ErrorStateWidget(
          message: e is AppException ? e.message : 'حدث خطأ في تحميل المنتج',
          onRetry: () => ref.invalidate(productDetailProvider(productId)),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, Product p) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Stack(
            children: [
              Container(
                height: 300,
                width: double.infinity,
                color: context.colors.bgSurface2,
                child: p.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: p.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => TammShimmer(
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: BorderRadius.circular(0),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.image,
                          size: 80,
                          color: context.colors.textFaint,
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.image,
                          size: 80,
                          color: context.colors.textFaint,
                        ),
                      ),
              ),
              if (p.isFeatured && !p.hasDiscount)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.warning,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'مميز ⭐',
                      style: AppTextStyles.bodySmall(
                        Colors.white,
                      ).copyWith(fontWeight: AppTextStyles.bold),
                    ),
                  ),
                ),
              if (p.hasDiscount)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.error,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'عرض خاص: خصم ${p.discountPercentage}% 🏷️',
                      style: AppTextStyles.bodySmall(
                        Colors.white,
                      ).copyWith(fontWeight: AppTextStyles.bold),
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
                AppSpacing.gapMd,
                if (p.brand != null)
                  Text(
                    p.brand!,
                    style: AppTextStyles.body(
                      context.colors.textSecond,
                    ).copyWith(fontWeight: AppTextStyles.bold),
                  ),
                Text(
                  p.name,
                  style: AppTextStyles.body(context.colors.textPrimary),
                ),
                AppSpacing.gapSm2,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      p.price != null
                          ? '${p.price!.toInt()} ر.س'
                          : 'السعر غير محدد',
                      style: AppTextStyles.body(context.colors.textPrimary),
                    ),
                    if (p.hasDiscount) ...[
                      AppSpacing.hGapSm,
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${p.oldPrice!.toInt()}',
                          style: AppTextStyles.body(context.colors.textPrimary),
                        ),
                      ),
                    ],
                  ],
                ),
                if (p.description != null) ...[
                  AppSpacing.gapLg,
                  Text(
                    'وصف المنتج',
                    style: AppTextStyles.cardTitle(context.colors.textPrimary),
                  ),
                  AppSpacing.gapXs,
                  Text(
                    p.description!,
                    style: AppTextStyles.body(context.colors.textPrimary),
                  ),
                ],
                if (p.specs.isNotEmpty) ...[
                  AppSpacing.gapLg,
                  Text(
                    'المواصفات التقنية',
                    style: AppTextStyles.body(context.colors.textPrimary),
                  ),
                  AppSpacing.gapSm2,
                  Container(
                    decoration: BoxDecoration(
                      color: context.colors.bgSurface,
                      borderRadius: AppSpacing.radius,
                      border: Border.all(color: context.colors.border),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      children: p.specs.entries.toList().asMap().entries.map((
                        entry,
                      ) {
                        final index = entry.key;
                        final spec = entry.value;
                        final isLast = index == p.specs.length - 1;
                        final isEven = index % 2 == 0;
                        final specName = specsTranslation[spec.key] ?? spec.key;
                        final icon = specsIcons[spec.key] ?? Icons.info_outline;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isEven
                                ? context.colors.bgSurface
                                : context.colors.bgSurface2,
                            border: isLast
                                ? null
                                : Border(
                                    bottom: BorderSide(
                                      color: context.colors.border,
                                    ),
                                  ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                icon,
                                size: 20,
                                color: context.colors.bluePrimary,
                              ),
                              AppSpacing.hGapSm2,
                              Expanded(
                                flex: 2,
                                child: Text(
                                  specName,
                                  style: AppTextStyles.body(
                                    context.colors.textSecond,
                                  ).copyWith(fontWeight: AppTextStyles.bold),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  '${spec.value}',
                                  style: AppTextStyles.body(
                                    context.colors.textPrimary,
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
                AppSpacing.gapXl,
                _RelatedProducts(currentProductId: p.id, category: p.category),
                AppSpacing.gapXl,
              ],
            ),
          ),
        ],
        ),
      ),
    ),
    _BottomPurchaseBar(
      product: p,
      bottomPadding: bottomPadding,
      onPressed: () => _addToCart(context, ref, p),
    ),
  ],
    );
  }

  Future<void> _addToCart(
    BuildContext context,
    WidgetRef ref,
    Product p,
  ) async {
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
      await cartNotifier.addItem(
        CartItem(product: p, includeInstallation: wantsInstallation),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                AppSpacing.hGapSm,
                Expanded(
                  child: Text(
                    'تم الإضافة: ${p.name}',
                    style: AppTextStyles.body(context.colors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: context.colors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'عرض السلة',
              textColor: Colors.white,
              onPressed: () =>
                  ref.read(appRouterProvider).push('/customer/cart'),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AppException ? e.message : 'تعذرت الإضافة للسلة',
              style: AppTextStyles.body(context.colors.textPrimary),
            ),
            backgroundColor: context.colors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}

class _BottomPurchaseBar extends StatelessWidget {
  final Product product;
  final double bottomPadding;
  final VoidCallback onPressed;

  const _BottomPurchaseBar({
    required this.product,
    required this.bottomPadding,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        border: Border(
          top: BorderSide(color: context.colors.border),
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.pagePadding.left,
        right: AppSpacing.pagePadding.right,
        top: AppSpacing.sm,
        bottom: AppSpacing.sm + bottomPadding,
      ),
      child: Row(
        children: [
          Expanded(
            child: p.price != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (p.hasDiscount)
                        Text(
                          '${p.oldPrice!.toInt()} ر.س',
                          style: AppTextStyles.caption(
                            context.colors.textFaint,
                          ).copyWith(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${p.price!.toInt()}',
                            style: AppTextStyles.price(
                              context.colors.bluePrimary,
                            ),
                          ),
                          AppSpacing.hGapXs,
                          Text(
                            'ر.س',
                            style: AppTextStyles.caption(
                              context.colors.textSecond,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Text(
                    'السعر غير محدد',
                    style: AppTextStyles.body(context.colors.textSecond),
                  ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: p.price != null
                ? TammButton(
                    label: p.requiresInstallation
                        ? 'اشترِ وركّب 🛠'
                        : 'أضف للسلة 🛒',
                    icon: p.requiresInstallation
                        ? Icons.build_outlined
                        : Icons.shopping_cart_outlined,
                    onPressed: onPressed,
                  )
                : TammButton(
                    label: 'تواصل معنا للسعر',
                    icon: Icons.chat_outlined,
                    type: TammButtonType.secondary,
                    onPressed: () => context.push('/customer/services'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RelatedProducts extends ConsumerWidget {
  final String currentProductId;
  final String category;
  const _RelatedProducts({
    required this.currentProductId,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatedAsync = ref.watch(productsProvider(category));
    return relatedAsync.when(
      data: (products) {
        final related = products
            .where((p) => p.id != currentProductId)
            .take(4)
            .toList();
        if (related.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'منتجات مشابهة',
              style: AppTextStyles.sectionTitle(context.colors.textPrimary),
            ),
            AppSpacing.gapMd,
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: related.length,
                separatorBuilder: (_, __) => AppSpacing.hGapSm2,
                itemBuilder: (_, i) {
                  final rp = related[i];
                  return GestureDetector(
                    onTap: () => context.push('/customer/product/${rp.id}'),
                    child: Container(
                      width: 150,
                      decoration: BoxDecoration(
                        color: context.colors.bgSurface,
                        borderRadius: AppSpacing.radius,
                        border: Border.all(color: context.colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: context.colors.bgSurface2,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(11),
                                ),
                              ),
                              child: rp.imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(11),
                                      ),
                                      child: CachedNetworkImage(
                                        imageUrl: rp.imageUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            TammShimmer(
                                              width: double.infinity,
                                              height: double.infinity,
                                              borderRadius:
                                                  BorderRadius.circular(0),
                                            ),
                                        errorWidget: (context, url, err) =>
                                            Icon(
                                              Icons.image,
                                              color: context.colors.textFaint,
                                            ),
                                      ),
                                    )
                                  : Center(
                                      child: Icon(
                                        Icons.image,
                                        color: context.colors.textFaint,
                                      ),
                                    ),
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
                                    style: AppTextStyles.body(
                                      context.colors.textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Text(
                                        rp.price != null
                                            ? '${rp.price!.toInt()}'
                                            : 'غير محدد',
                                        style:
                                            AppTextStyles.bodySmall(
                                              context.colors.blueSky,
                                            ).copyWith(
                                              fontWeight: AppTextStyles.bold,
                                            ),
                                      ),
                                      if (rp.price != null)
                                        Text(
                                          ' ر.س',
                                          style: AppTextStyles.badge(
                                            context.colors.blueSky,
                                          ),
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
