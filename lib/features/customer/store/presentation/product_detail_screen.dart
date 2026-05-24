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
import '../../../../core/utils/auth_guard.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import 'buy_install_sheet.dart';
import '../widgets/cart_icon_button.dart';
import '../widgets/product_card.dart';
import '../../../../core/widgets/cart_toast.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: const TammAppBar(
        title: 'تفاصيل المنتج',
        actions: [CartIconButton()],
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
                _PremiumProductGallery(product: p),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p.hasDiscount && p.oldPrice != null)
                            Text(
                              '${p.oldPrice!.toInt()} ر.س',
                              style:
                                  AppTextStyles.bodySmall(
                                    context.colors.textSecond,
                                  ).copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    decorationThickness: 1.8,
                                    decorationColor: context.colors.textSecond,
                                  ),
                            ),
                          Text(
                            p.price != null
                                ? '${p.price!.toInt()} ر.س'
                                : 'السعر غير محدد',
                            style: AppTextStyles.price(
                              context.colors.bluePrimary,
                            ),
                          ),
                        ],
                      ),
                      if (p.price != null && p.isOutOfStock) ...[
                        AppSpacing.gapSm2,
                        _StockBadge(
                          label: 'نفدت الكمية',
                          icon: Icons.remove_shopping_cart_outlined,
                          color: context.colors.error,
                        ),
                      ] else if (p.price != null && p.isLowStock) ...[
                        AppSpacing.gapSm2,
                        _StockBadge(
                          label: 'متبقي عدد محدود — ${p.stockQuantity} قطع فقط',
                          icon: Icons.warning_amber_outlined,
                          color: context.colors.warning,
                        ),
                      ],
                      if (p.description != null) ...[
                        AppSpacing.gapLg,
                        Text(
                          'وصف المنتج',
                          style: AppTextStyles.cardTitle(
                            context.colors.textPrimary,
                          ),
                        ),
                        AppSpacing.gapXs,
                        _ExpandableText(text: p.description!),
                      ],
                      if (p.specs.isNotEmpty) ...[
                        AppSpacing.gapLg,
                        Text(
                          'المواصفات التقنية',
                          style: AppTextStyles.body(context.colors.textPrimary),
                        ),
                        AppSpacing.gapSm2,
                        _ExpandableSpecs(specs: p.specs),
                      ],
                      AppSpacing.gapXl,
                      _RelatedProducts(
                        currentProductId: p.id,
                        category: p.category,
                      ),
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

  void _showStockError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.body(Colors.white)),
        backgroundColor: context.colors.warning,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _addToCart(
    BuildContext context,
    WidgetRef ref,
    Product p,
  ) async {
    if (!await requireAuth(context, ref)) return;

    // فحص المخزون قبل أي خطوة
    if (p.isOutOfStock) {
      if (context.mounted) {
        _showStockError(
          context,
          'عذراً، هذا المنتج غير متوفر حالياً في المخزن.',
        );
      }
      return;
    }
    final cart = ref.read(cartProvider).valueOrNull ?? [];
    final qtyInCart = cart
        .where((c) => c.product.id == p.id)
        .fold<int>(0, (s, c) => s + c.quantity);
    if (qtyInCart + 1 > p.stockQuantity) {
      if (context.mounted) {
        _showStockError(
          context,
          'المتوفر في المخزن ${p.stockQuantity} قطعة فقط، ولديك $qtyInCart في السلة.',
        );
      }
      return;
    }

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
      await ref
          .read(cartProvider.notifier)
          .addItem(
            CartItem(product: p, includeInstallation: wantsInstallation),
          );
      if (context.mounted) CartToast.show(context, productName: p.name);
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
        border: Border(top: BorderSide(color: context.colors.border)),
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
                          ).copyWith(decoration: TextDecoration.lineThrough),
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
                ? (p.isOutOfStock
                      ? const TammButton(
                          label: 'نفدت الكمية',
                          icon: Icons.remove_shopping_cart_outlined,
                          type: TammButtonType.secondary,
                          onPressed: null,
                        )
                      : TammButton(
                          label: p.requiresInstallation
                              ? 'اشترِ وركّب 🛠'
                              : 'أضف للسلة 🛒',
                          icon: p.requiresInstallation
                              ? Icons.build_outlined
                              : Icons.shopping_cart_outlined,
                          onPressed: onPressed,
                        ))
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
                itemBuilder: (_, i) =>
                    ProductCard(product: related[i], width: 150),
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

class _ExpandableText extends StatefulWidget {
  final String text;
  const _ExpandableText({required this.text});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;
  static const int _collapsedLines = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Text(
            widget.text,
            style: AppTextStyles.body(context.colors.textSecond),
            maxLines: _collapsedLines,
            overflow: TextOverflow.ellipsis,
          ),
          secondChild: Text(
            widget.text,
            style: AppTextStyles.body(context.colors.textSecond),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(
            _expanded ? 'إخفاء ▲' : 'اقرأ المزيد ▼',
            style: AppTextStyles.bodySmall(
              context.colors.bluePrimary,
            ).copyWith(fontWeight: AppTextStyles.semiBold),
          ),
        ),
      ],
    );
  }
}

// ─── Expandable Specs ─────────────────────────────────────────────────────────

class _ExpandableSpecs extends StatefulWidget {
  final Map<String, dynamic> specs;
  const _ExpandableSpecs({required this.specs});

  @override
  State<_ExpandableSpecs> createState() => _ExpandableSpecsState();
}

class _ExpandableSpecsState extends State<_ExpandableSpecs> {
  static const int _defaultVisible = 4;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final entries = widget.specs.entries.toList();
    final total = entries.length;
    final showToggle = total > _defaultVisible;
    final visible = _expanded
        ? entries
        : entries.take(_defaultVisible).toList();

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.bgSurface,
              borderRadius: AppSpacing.radius,
              border: Border.all(color: context.colors.border),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: visible.asMap().entries.map((entry) {
                final index = entry.key;
                final spec = entry.value;
                final isLast = index == visible.length - 1;
                final isEven = index % 2 == 0;
                final specName = specsTranslation[spec.key] ?? spec.key;
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
                            bottom: BorderSide(color: context.colors.border),
                          ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          specName,
                          style: AppTextStyles.bodySmall(
                            context.colors.textSecond,
                          ).copyWith(fontWeight: AppTextStyles.semiBold),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          '${spec.value}',
                          style: AppTextStyles.bodySmall(
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
        ),
        if (showToggle) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'إخفاء ▲' : 'عرض كل المواصفات ($total) ▼',
              style: AppTextStyles.bodySmall(
                context.colors.bluePrimary,
              ).copyWith(fontWeight: AppTextStyles.semiBold),
            ),
          ),
        ],
      ],
    );
  }
}

class _StockBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _StockBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppSpacing.radiusFull,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          AppSpacing.hGapXs,
          Text(
            label,
            style: AppTextStyles.caption(
              color,
            ).copyWith(fontWeight: AppTextStyles.semiBold),
          ),
        ],
      ),
    );
  }
}

// ─── معرض الصور الدوار المتفاعل الفاخر ───────────────────────────────────────────

class _PremiumProductGallery extends StatefulWidget {
  final Product product;
  const _PremiumProductGallery({required this.product});

  @override
  State<_PremiumProductGallery> createState() => _PremiumProductGalleryState();
}

class _PremiumProductGalleryState extends State<_PremiumProductGallery> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final urls = widget.product.allImageUrls;
    if (urls.isEmpty) {
      return Container(
        height: 320,
        width: double.infinity,
        color: context.colors.bgSurface2,
        child: Center(
          child: Icon(
            Icons.image_outlined,
            size: 80,
            color: context.colors.textFaint,
          ),
        ),
      );
    }

    return Stack(
      children: [
        // المعرض الدوار الرئيسي
        Container(
          height: 320,
          width: double.infinity,
          color: context.colors.bgSurface2,
          child: PageView.builder(
            itemCount: urls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _FullScreenGallery(
                        imageUrls: urls,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: urls[index],
                  child: CachedNetworkImage(
                    imageUrl: urls[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => TammShimmer(
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: BorderRadius.circular(0),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.image_outlined,
                      size: 80,
                      color: context.colors.textFaint,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // الشارات العائمة الزجاجية
        if (widget.product.isFeatured && !widget.product.hasDiscount)
          Positioned(
            top: 16,
            right: 16,
            child: _GlassmorphicBadge(
              label: 'مميز ⭐',
              color: context.colors.warning,
            ),
          ),
        if (widget.product.hasDiscount)
          Positioned(
            top: 16,
            right: 16,
            child: _GlassmorphicBadge(
              label: 'خصم ${widget.product.discountPercentage}% 🏷️',
              color: context.colors.error,
            ),
          ),
        // مؤشر التصفح النقطي المخصص ذو الحركات الصغرى الفاخرة
        if (urls.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(urls.length, (index) {
                final isSelected = _currentIndex == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: isSelected ? 18 : 6,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.colors.bluePrimary
                        : context.colors.textFaint.withValues(alpha: 0.5),
                    borderRadius: AppSpacing.radiusFull,
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _GlassmorphicBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _GlassmorphicBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppSpacing.radiusSm,
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall(
          Colors.white,
        ).copyWith(fontWeight: AppTextStyles.bold),
      ),
    );
  }
}

// ─── نافذة المعاينة الكبرى والتكبير ────────────────────────────────────────────────

class _FullScreenGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  const _FullScreenGallery({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // صور شاشة كاملة
          GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null &&
                  details.primaryVelocity!.abs() > 400) {
                Navigator.pop(context);
              }
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Center(
                    child: Hero(
                      tag: widget.imageUrls[index],
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrls[index],
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.image_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // زر الإغلاق العائم الزجاجي
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: ClipRRect(
              borderRadius: AppSpacing.radiusFull,
              child: Material(
                color: Colors.white.withValues(alpha: 0.15),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          // مؤشر الصفحة الرقمي الفاخر
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: AppSpacing.radiusFull,
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.imageUrls.length}',
                    style: AppTextStyles.bodySmall(Colors.white).copyWith(
                      fontWeight: AppTextStyles.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
