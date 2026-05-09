import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_shimmer.dart';
import '../../../../core/widgets/responsive_wrapper.dart';
import '../../../../shared/providers/product_providers.dart';
import '../../../../shared/providers/auth_providers.dart';
import '../../../../shared/providers/order_providers.dart';
import '../../../../shared/models/product.dart';
import '../widgets/promo_slider.dart';
import '../../../../core/widgets/tamm_notification_bell.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final featuredAsync = ref.watch(featuredProductsProvider);
    final dealsAsync = ref.watch(dealsProvider);
    final isGuest = ref.watch(isGuestProvider);

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      body: SafeArea(
        child: ResponsiveWrapper(
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header with Icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          profileAsync.when(
                            data: (p) => Text(
                              'أهلاً ${p?.fullName.isNotEmpty == true ? p!.fullName : 'بك'} 👋',
                              style: GoogleFonts.harmattan(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: context.colors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'كيف نقدر نخدمك اليوم؟',
                            style: GoogleFonts.harmattan(
                              fontSize: 16,
                              color: context.colors.textSecond,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const TammNotificationBell(),
                        if (!isGuest) ...[
                          _HeaderIcon(
                            icon: Icons.receipt_long_outlined,
                            onTap: () => context.push('/customer/orders'),
                          ),
                          const SizedBox(width: 8),
                          Consumer(
                            builder: (context, ref, child) {
                              final count = ref.watch(cartCountProvider);
                              return _HeaderIcon(
                                icon: Icons.shopping_cart_outlined,
                                badgeCount: count,
                                onTap: () => context.push('/customer/cart'),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Search Bar
                GestureDetector(
                  onTap: () {
                    context.push('/customer/search');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.bgSurface,
                      borderRadius: AppSpacing.radius,
                      border: Border.all(color: context.colors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: context.colors.textSecond),
                        const SizedBox(width: 8),
                        Text(
                          'ابحث عن منتجات، مكيفات، ألواح...',
                          style: GoogleFonts.harmattan(
                            fontSize: 16,
                            color: context.colors.textSecond,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Promo Slider
                const PromoSlider(),
                const SizedBox(height: 32),

                // 5. Quick Services (3 Cards)
                Text(
                  'خدمات سريعة',
                  style: GoogleFonts.harmattan(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickServiceCard(
                        icon: Icons.ac_unit,
                        label: 'تركيب',
                        onTap: () => context.push(
                          '/customer/services?category=ac_install',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickServiceCard(
                        icon: Icons.build,
                        label: 'صيانة',
                        onTap: () => context.push(
                          '/customer/services?category=ac_repair',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickServiceCard(
                        icon: Icons.support_agent,
                        label: 'استشارة',
                        onTap: () => context.push(
                          '/customer/services?category=consultation',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 6. Most Popular (Featured Products)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الأكثر طلباً 🔥',
                      style: GoogleFonts.harmattan(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/customer/store'),
                      child: Text(
                        'عرض الكل',
                        style: GoogleFonts.harmattan(
                          color: context.colors.blueLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                featuredAsync.when(
                  data: (products) => _buildProductList(context, products),
                  loading: () => _buildShimmerList(),
                  error: (e, _) => ErrorStateWidget(
                    message: e is AppException
                        ? e.message
                        : 'حدث خطأ في تحميل المنتجات',
                    onRetry: () => ref.refresh(featuredProductsProvider),
                  ),
                ),
                const SizedBox(height: 32),

                // 7. Special Deals
                dealsAsync.when(
                  data: (deals) {
                    if (deals.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'عروض وأسعار مميزة 🏷️',
                              style: GoogleFonts.harmattan(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: context.colors.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/customer/store'),
                              child: Text(
                                'تصفح العروض',
                                style: GoogleFonts.harmattan(
                                  color: context.colors.blueLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildProductList(context, deals),
                        const SizedBox(height: 32),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductList(BuildContext context, List<Product> products) {
    if (products.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final p = products[i];
          return GestureDetector(
            onTap: () => context.push('/customer/product/${p.id}'),
            child: Container(
              width: 160,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.bgSurface,
                borderRadius: AppSpacing.radius,
                border: Border.all(color: context.colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: context.colors.bgSurface2,
                            borderRadius: AppSpacing.radiusSm,
                          ),
                          child: p.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: AppSpacing.radiusSm,
                                  child: CachedNetworkImage(
                                    imageUrl: p.imageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    placeholder: (context, url) =>
                                        const TammShimmer(
                                          width: double.infinity,
                                          height: double.infinity,
                                          borderRadius: AppSpacing.radiusSm,
                                        ),
                                    errorWidget: (context, url, err) => Icon(
                                      Icons.image,
                                      color: context.colors.textFaint,
                                      size: 40,
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                    Icons.image,
                                    color: context.colors.textFaint,
                                    size: 40,
                                  ),
                                ),
                        ),
                        if (p.isFeatured && !p.hasDiscount)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: context.colors.warning,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'مميز',
                                style: GoogleFonts.harmattan(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        if (p.hasDiscount)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: context.colors.error,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'خصم ${p.discountPercentage}%',
                                style: GoogleFonts.harmattan(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.name,
                    style: GoogleFonts.harmattan(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        p.price != null
                            ? '${p.price!.toInt()}'
                            : 'السعر غير محدد',
                        style: GoogleFonts.harmattan(
                          fontSize: 14,
                          color: context.colors.blueSky,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (p.price != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          'ر.س',
                          style: GoogleFonts.harmattan(
                            fontSize: 10,
                            color: context.colors.blueSky,
                          ),
                        ),
                      ],
                      if (p.hasDiscount) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${p.oldPrice!.toInt()}',
                          style: GoogleFonts.harmattan(
                            fontSize: 12,
                            color: context.colors.textSecond,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerList() {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => TammShimmer(
          width: 160,
          height: 200,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  const _HeaderIcon({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Badge(
        isLabelVisible: badgeCount > 0,
        label: Text('$badgeCount'),
        backgroundColor: context.colors.error,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.colors.bluePrimary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: context.colors.blueSky, size: 24),
        ),
      ),
    );
  }
}

class _QuickServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickServiceCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: context.colors.bgSurface,
          border: Border.all(color: context.colors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          borderRadius: AppSpacing.radius,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: context.colors.bluePrimary, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.harmattan(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
