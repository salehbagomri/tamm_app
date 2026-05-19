import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/tamm_shimmer.dart';
import '../../store/widgets/product_card.dart';
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
                              style: AppTextStyles.h3(
                                context.colors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          AppSpacing.gapXs,
                          Text(
                            'كيف نقدر نخدمك اليوم؟',
                            style: AppTextStyles.body(
                              context.colors.textSecond,
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
                          AppSpacing.hGapSm,
                          _HeaderIcon(
                            icon: Icons.receipt_long_outlined,
                            onTap: () => context.push('/customer/orders'),
                          ),
                          AppSpacing.hGapSm,
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
                AppSpacing.gapLg,

                // 2. Search Bar
                GestureDetector(
                  onTap: () {
                    context.push('/customer/search');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm2,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.bgSurface,
                      borderRadius: AppSpacing.radius,
                      border: Border.all(color: context.colors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_outlined, color: context.colors.textSecond),
                        AppSpacing.hGapSm,
                        Text(
                          'ابحث عن منتجات، مكيفات، ألواح...',
                          style: AppTextStyles.body(context.colors.textSecond),
                        ),
                      ],
                    ),
                  ),
                ),
                AppSpacing.gapLg,

                // 4. Promo Slider
                const PromoSlider(),
                AppSpacing.gapSection,

                // 5. Quick Services (3 Cards)
                Text(
                  'خدمات سريعة',
                  style: AppTextStyles.sectionTitle(context.colors.textPrimary),
                ),
                AppSpacing.gapSm2,
                Row(
                  children: [
                    Expanded(
                      child: _QuickServiceCard(
                        icon: Icons.ac_unit_outlined,
                        label: 'تركيب',
                        onTap: () => context.push(
                          '/customer/services?category=ac_install',
                        ),
                      ),
                    ),
                    AppSpacing.hGapSm2,
                    Expanded(
                      child: _QuickServiceCard(
                        icon: Icons.build_outlined,
                        label: 'صيانة',
                        onTap: () => context.push(
                          '/customer/services?category=ac_repair',
                        ),
                      ),
                    ),
                    AppSpacing.hGapSm2,
                    Expanded(
                      child: _QuickServiceCard(
                        icon: Icons.support_agent_outlined,
                        label: 'استشارة',
                        onTap: () => context.push(
                          '/customer/services?category=consultation',
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapSection,

                // 6. Most Popular (Featured Products)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الأكثر طلباً 🔥',
                      style: AppTextStyles.sectionTitle(
                        context.colors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.push('/customer/catalog/best_sellers'),
                      child: Text(
                        'عرض الكل',
                        style: AppTextStyles.body(context.colors.blueLight),
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapSm2,
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
                AppSpacing.gapSection,

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
                              style: AppTextStyles.sectionTitle(
                                context.colors.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.push('/customer/catalog/deals'),
                              child: Text(
                                'تصفح العروض',
                                style: AppTextStyles.body(
                                  context.colors.blueLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapSm2,
                        _buildProductList(context, deals),
                        AppSpacing.gapSection,
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
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => AppSpacing.hGapSm2,
        itemBuilder: (_, i) => ProductCard(product: products[i], width: 150),
      ),
    );
  }

  Widget _buildShimmerList() {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => AppSpacing.hGapSm2,
        itemBuilder: (_, __) => const TammShimmer(
          width: 160,
          height: 200,
          borderRadius: AppSpacing.radius,
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
          padding: AppSpacing.iconCirclePadding,
          decoration: BoxDecoration(
            color: context.colors.bluePrimary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: context.colors.blueSky,
            size: AppSpacing.iconMd,
          ),
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
            Icon(
              icon,
              color: context.colors.bluePrimary,
              size: AppSpacing.iconLg,
            ),
            AppSpacing.gapXs,
            Text(
              label,
              style: AppTextStyles.bodySmall(
                context.colors.textPrimary,
              ).copyWith(fontWeight: AppTextStyles.semiBold),
            ),
          ],
        ),
      ),
    );
  }
}
