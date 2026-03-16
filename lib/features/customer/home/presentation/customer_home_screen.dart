import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_shimmer.dart';
import '../../../../shared/providers/product_providers.dart';
import '../../../../shared/providers/auth_providers.dart';
import '../widgets/active_order_card.dart';
import '../widgets/buy_install_banner.dart';
import '../widgets/recent_orders.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final featuredAsync = ref.watch(featuredProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              profileAsync.when(
                data: (p) => Text(
                  'أهلاً ${p?.fullName ?? ''}',
                  style: GoogleFonts.harmattan(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.welcomeSub,
                style: GoogleFonts.harmattan(
                  fontSize: 16,
                  color: AppColors.textSecond,
                ),
              ),
              const ActiveOrderCard(),
              const SizedBox(height: 24),

              Text(
                'خدمات سريعة',
                style: GoogleFonts.harmattan(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - AppSpacing.pagePadding.horizontal - 24) / 3,
                    child: _QuickServiceCard(
                      icon: Icons.ac_unit,
                      label: 'تركيب',
                      onTap: () =>
                          context.push('/customer/services?category=ac_install'),
                    ),
                  ),
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - AppSpacing.pagePadding.horizontal - 24) / 3,
                    child: _QuickServiceCard(
                      icon: Icons.build,
                      label: 'صيانة',
                      onTap: () =>
                          context.push('/customer/services?category=ac_repair'),
                    ),
                  ),
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - AppSpacing.pagePadding.horizontal - 24) / 3,
                    child: _QuickServiceCard(
                      icon: Icons.support_agent,
                      label: 'استشارة',
                      onTap: () => context.push(
                        '/customer/services?category=consultation',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - AppSpacing.pagePadding.horizontal - 12) / 2,
                    child: _QuickServiceCard(
                      icon: Icons.cleaning_services,
                      label: 'غسيل',
                      onTap: () => context.push(
                        '/customer/services?category=ac_wash',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - AppSpacing.pagePadding.horizontal - 12) / 2,
                    child: _QuickServiceCard(
                      icon: Icons.solar_power,
                      label: 'طاقة شمسية',
                      onTap: () => context.push(
                        '/customer/services?category=solar_install',
                      ),
                    ),
                  ),
                ],
              ),
              const BuyInstallBanner(),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'منتجات مميزة',
                    style: GoogleFonts.harmattan(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/customer/store'),
                    child: Text(
                      'عرض الكل',
                      style: GoogleFonts.harmattan(color: AppColors.blueLight),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              featuredAsync.when(
                data: (products) => SizedBox(
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
                            color: AppColors.bgSurface,
                            borderRadius: AppSpacing.radius,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: AppColors.bgSurface2,
                                    borderRadius: AppSpacing.radiusSm,
                                  ),
                                  child: p.imageUrl != null
                                      ? ClipRRect(
                                          borderRadius: AppSpacing.radiusSm,
                                          child: Image.network(
                                            p.imageUrl!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
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
                              const SizedBox(height: 8),
                              Text(
                                p.name,
                                style: GoogleFonts.harmattan(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.price != null
                                    ? '${p.price!.toInt()} ر.س'
                                    : AppStrings.requestQuote,
                                style: GoogleFonts.harmattan(
                                  fontSize: 14,
                                  color: AppColors.blueSky,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                loading: () => SizedBox(
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
                ),
                error: (e, _) => Text('$e'),
              ),
              const SizedBox(height: 32),
              const RecentOrders(),
              const SizedBox(height: 32),
            ],
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.blueDark, AppColors.blueMid],
          ),
          borderRadius: AppSpacing.radius,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.blueSky, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.harmattan(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
