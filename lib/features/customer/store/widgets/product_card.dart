import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../../core/widgets/cart_toast.dart';
import '../../../../core/widgets/tamm_shimmer.dart';
import '../../../../shared/models/cart_item.dart';
import '../../../../shared/models/product.dart';
import '../../../../shared/providers/favorites_providers.dart';
import '../../../../shared/providers/order_providers.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';
import '../presentation/buy_install_sheet.dart';

class ProductCard extends ConsumerStatefulWidget {
  final Product product;

  /// تحديد العرض — للقائمة الأفقية في الرئيسية. null = يمتد داخل الـ grid
  final double? width;

  const ProductCard({super.key, required this.product, this.width});

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool _loading = false;

  void _showStockError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.body(Colors.white)),
        backgroundColor: context.colors.warning,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _addToCart() async {
    if (_loading) return;
    if (!await requireAuth(context, ref)) return;
    if (!mounted) return;

    // فحص المخزون
    final p = widget.product;
    if (p.isOutOfStock) {
      _showStockError('عذراً، هذا المنتج غير متوفر حالياً في المخزن.');
      return;
    }
    final cart = ref.read(cartProvider).valueOrNull ?? [];
    final qtyInCart = cart
        .where((c) => c.product.id == p.id)
        .fold<int>(0, (s, c) => s + c.quantity);
    if (qtyInCart + 1 > p.stockQuantity) {
      _showStockError(
        'المتوفر في المخزن ${p.stockQuantity} قطعة فقط، ولديك $qtyInCart في السلة.',
      );
      return;
    }

    bool wantsInstallation = false;
    if (widget.product.requiresInstallation) {
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const BuyInstallSheet(),
      );
      if (!mounted) return;
      if (result == null) return;
      wantsInstallation = result;
    }

    setState(() => _loading = true);
    try {
      await ref
          .read(cartProvider.notifier)
          .addItem(
            CartItem(
              product: widget.product,
              includeInstallation: wantsInstallation,
            ),
          );
      if (!mounted) return;
      CartToast.show(context, productName: widget.product.name);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is AppException ? e.message : 'تعذرت الإضافة للسلة',
            style: AppTextStyles.body(context.colors.textPrimary),
          ),
          backgroundColor: context.colors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return GestureDetector(
      onTap: () => context.push('/customer/product/${p.id}'),
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          color: context.colors.bgSurface,
          borderRadius: AppSpacing.radius,
          border: Border.all(color: context.colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductImage(product: p),
            _ProductInfo(
              product: p,
              loading: _loading,
              onAddToCart: _addToCart,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Image section ────────────────────────────────────────────────────────────

class _ProductImage extends StatelessWidget {
  final Product product;
  const _ProductImage({required this.product});

  static const _imageRadius = BorderRadius.vertical(
    top: Radius.circular(AppSpacing.radiusValue),
  );

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.colors.bgSurface2,
              borderRadius: _imageRadius,
            ),
            child: ClipRRect(
              borderRadius: _imageRadius,
              child: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) => const TammShimmer(
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: _imageRadius,
                      ),
                      errorWidget: (_, __, ___) => _PlaceholderIcon(),
                    )
                  : _PlaceholderIcon(),
            ),
          ),
          if (product.hasDiscount)
            Positioned(
              top: 6,
              right: 6,
              child: _Badge(
                label: 'خصم ${product.discountPercentage}%',
                color: context.colors.error,
              ),
            )
          else if (product.isFeatured)
            Positioned(
              top: 6,
              right: 6,
              child: _Badge(label: 'مميز', color: context.colors.warning),
            ),
          if (product.isOutOfStock)
            Positioned(
              bottom: 6,
              left: 6,
              child: _Badge(label: 'نفدت', color: context.colors.error),
            )
          else if (product.isLowStock)
            Positioned(
              bottom: 6,
              left: 6,
              child: _Badge(
                label: '${product.stockQuantity} متبقية',
                color: context.colors.warning,
              ),
            ),
          Positioned(
            top: 6,
            left: 6,
            child: _FavoriteButton(productId: product.id),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Icon(
      Icons.image_outlined,
      color: context.colors.textFaint,
      size: 40,
    ),
  );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppSpacing.radiusXs,
      ),
      child: Text(
        label,
        style: AppTextStyles.badge(
          Colors.white,
        ).copyWith(fontWeight: AppTextStyles.bold),
      ),
    );
  }
}

// ─── Favorite heart button ────────────────────────────────────────────────────

class _FavoriteButton extends ConsumerStatefulWidget {
  final String productId;
  const _FavoriteButton({required this.productId});

  @override
  ConsumerState<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<_FavoriteButton> {
  bool? _optimistic; // null = follow provider, bool = local override
  bool _busy = false;

  Future<void> _toggle(bool currentlyFav) async {
    if (_busy) return;
    setState(() {
      _optimistic = !currentlyFav;
      _busy = true;
    });
    try {
      final repo = ref.read(favoritesRepositoryProvider);
      if (currentlyFav) {
        await repo.remove(widget.productId);
      } else {
        await repo.add(widget.productId);
      }
      ref.invalidate(favoritedIdsProvider);
      ref.invalidate(favoriteProductsProvider);
    } catch (_) {
      if (mounted) setState(() => _optimistic = currentlyFav);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final idsAsync = ref.watch(favoritedIdsProvider);
    final isFav =
        _optimistic ??
        idsAsync.whenOrNull(data: (ids) => ids.contains(widget.productId)) ??
        false;

    return GestureDetector(
      onTap: () => _toggle(isFav),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: context.colors.bgSurface.withValues(alpha: 0.85),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
          size: 18,
          color: isFav ? context.colors.error : context.colors.textSecond,
        ),
      ),
    );
  }
}

// ─── Info section ─────────────────────────────────────────────────────────────

class _ProductInfo extends StatelessWidget {
  final Product product;
  final bool loading;
  final VoidCallback onAddToCart;

  const _ProductInfo({
    required this.product,
    required this.loading,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm2,
        AppSpacing.sm,
        AppSpacing.sm2,
        AppSpacing.sm2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            p.name,
            style: AppTextStyles.bodySmall(
              context.colors.textPrimary,
            ).copyWith(fontWeight: AppTextStyles.semiBold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _PriceSection(product: p)),
              if (p.price != null) ...[
                const SizedBox(width: 6),
                _AddToCartButton(
                  loading: loading,
                  disabled: p.isOutOfStock,
                  onTap: onAddToCart,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceSection extends StatelessWidget {
  final Product product;
  const _PriceSection({required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (p.hasDiscount && p.oldPrice != null)
          Text(
            '${p.oldPrice!.toInt()} ر.س',
            style: AppTextStyles.bodySmall(context.colors.textSecond).copyWith(
              decoration: TextDecoration.lineThrough,
              decorationThickness: 1.8,
              decorationColor: context.colors.textSecond,
            ),
          ),
        Text(
          p.price != null ? '${p.price!.toInt()} ر.س' : 'السعر غير محدد',
          style: AppTextStyles.label(
            context.colors.blueSky,
          ).copyWith(fontWeight: AppTextStyles.bold),
        ),
      ],
    );
  }
}

class _AddToCartButton extends StatelessWidget {
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;
  const _AddToCartButton({
    required this.loading,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = disabled
        ? context.colors.textFaint
        : context.colors.blueSky;
    final bgColor = disabled
        ? context.colors.textFaint.withValues(alpha: 0.1)
        : context.colors.bluePrimary.withValues(alpha: 0.1);
    return InkWell(
      onTap: (loading || disabled) ? null : onTap,
      borderRadius: AppSpacing.radiusSm,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppSpacing.radiusSm,
        ),
        child: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: iconColor,
                ),
              )
            : Icon(
                disabled
                    ? Icons.block_outlined
                    : Icons.add_shopping_cart_outlined,
                size: 18,
                color: iconColor,
              ),
      ),
    );
  }
}
