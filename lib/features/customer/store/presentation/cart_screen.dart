import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../core/widgets/tamm_shimmer.dart';
import '../../../../shared/providers/order_providers.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: const TammAppBar(title: 'السلة'),
      body: cartAsync.when(
        data: (cart) {
          if (cart.isEmpty) {
            return const TammEmptyState(
              icon: Icons.shopping_cart_outlined,
              message: 'السلة فارغة',
            );
          }

          // Calculate totals
          double originalTotal = 0.0;
          double finalTotal = notifier.total;
          
          for (final item in cart) {
            final double basePrice = item.product.oldPrice ?? item.product.price ?? 0;
            final double baseTotal = basePrice * item.quantity;
            final double installTotal = item.includeInstallation ? (item.product.installationPrice * item.quantity) : 0;
            originalTotal += baseTotal + installTotal;
          }
          
          final double savings = originalTotal - finalTotal;

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: AppSpacing.pagePadding,
                  itemCount: cart.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final item = cart[i];
                    return Dismissible(
                      key: Key(item.product.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.8),
                          borderRadius: AppSpacing.radius,
                        ),
                        alignment: Alignment.centerRight,
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        notifier.removeItem(item.product.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: AppSpacing.radius,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                color: AppColors.bgSurface2,
                                borderRadius: AppSpacing.radiusSm,
                              ),
                              child: item.product.imageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: item.product.imageUrl!,
                                      fit: BoxFit.cover,
                                      imageBuilder: (context, imageProvider) => Container(
                                        decoration: BoxDecoration(
                                          borderRadius: AppSpacing.radiusSm,
                                          image: DecorationImage(
                                            image: imageProvider,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      placeholder: (context, url) => TammShimmer(
                                        width: double.infinity,
                                        height: double.infinity,
                                        borderRadius: AppSpacing.radiusSm,
                                      ),
                                      errorWidget: (context, url, err) => const Icon(Icons.image, color: AppColors.textFaint),
                                    )
                                  : const Icon(Icons.image, color: AppColors.textFaint),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: GoogleFonts.harmattan(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  if (item.product.hasDiscount)
                                    Row(
                                      children: [
                                        Text(
                                          '${(item.product.oldPrice! * item.quantity).toInt()}',
                                          style: GoogleFonts.harmattan(
                                            fontSize: 13,
                                            color: AppColors.textSecond,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'وفرت ${((item.product.oldPrice! - item.product.price!) * item.quantity).toInt()} ر.س',
                                          style: GoogleFonts.harmattan(
                                            fontSize: 13,
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  Text(
                                    '${((item.product.price ?? 0) * item.quantity).toInt()} ر.س',
                                    style: GoogleFonts.harmattan(
                                      fontSize: 16,
                                      color: AppColors.blueSky,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                    ),
                                  ),
                                  if (item.includeInstallation)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.handyman, size: 14, color: AppColors.bluePrimary),
                                          const SizedBox(width: 4),
                                          Text(
                                            'تركيب (+${(item.product.installationPrice * item.quantity).toInt()})',
                                            style: GoogleFonts.harmattan(fontSize: 13, color: AppColors.bluePrimary),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  icon: const Icon(Icons.add_circle_outline, color: AppColors.bluePrimary, size: 24),
                                  onPressed: () => notifier.updateQuantity(item.product.id, item.quantity + 1),
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: GoogleFonts.harmattan(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.textSecond, size: 24),
                                  onPressed: () => notifier.updateQuantity(item.product.id, item.quantity - 1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: AppSpacing.pagePadding,
                decoration: const BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4)),
                  ],
                ),
                child: Column(
                  children: [
                    if (savings > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('المجموع الأصلي', style: GoogleFonts.harmattan(fontSize: 16, color: AppColors.textSecond)),
                          Text('${originalTotal.toInt()} ر.س', style: GoogleFonts.harmattan(fontSize: 16, color: AppColors.textSecond, decoration: TextDecoration.lineThrough)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('إجمالي التوفير', style: GoogleFonts.harmattan(fontSize: 16, color: AppColors.success, fontWeight: FontWeight.w600)),
                          Text('-${savings.toInt()} ر.س', style: GoogleFonts.harmattan(fontSize: 16, color: AppColors.success, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: AppColors.border),
                      ),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'المبلغ الإجمالي',
                          style: GoogleFonts.harmattan(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        Text(
                          '${finalTotal.toInt()} ر.س',
                          style: GoogleFonts.harmattan(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.blueSky, height: 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TammButton(
                        label: AppStrings.checkout,
                        onPressed: () => context.push('/customer/checkout'),
                      ),
                    ),
                    const SizedBox(height: 8), // For safe area
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => ListView.separated(
          padding: AppSpacing.pagePadding,
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, __) => TammShimmer(
            width: double.infinity,
            height: 96,
            borderRadius: AppSpacing.radius,
          ),
        ),
        error: (e, _) => TammEmptyState(
          icon: Icons.error_outline,
          message: 'حدث خطأ أثناء تحميل السلة: $e',
        ),
      ),
    );
  }
}

