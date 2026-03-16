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
                          color: AppColors.error.withOpacity(0.8),
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
                          children: [
                            Container(
                              width: 60,
                              height: 60,
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
                                      errorWidget: (context, url, err) => const Icon(
                                        Icons.image,
                                        color: AppColors.textFaint,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.image,
                                      color: AppColors.textFaint,
                                    ),
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
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                    Text(
                                      '${((item.product.price ?? 0) * item.quantity).toInt()} ر.س',
                                      style: GoogleFonts.harmattan(
                                        fontSize: 14,
                                        color: AppColors.blueSky,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (item.includeInstallation)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.handyman, size: 12, color: AppColors.bluePrimary),
                                            const SizedBox(width: 4),
                                            Text(
                                              'تركيب (+${item.product.installationPrice.toInt()})',
                                              style: GoogleFonts.harmattan(
                                                fontSize: 12,
                                                color: AppColors.bluePrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: AppColors.textSecond,
                                    size: 22,
                                  ),
                                  onPressed: () => notifier.updateQuantity(
                                    item.product.id,
                                    item.quantity - 1,
                                  ),
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
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: AppColors.bluePrimary,
                                    size: 22,
                                  ),
                                  onPressed: () => notifier.updateQuantity(
                                    item.product.id,
                                    item.quantity + 1,
                                  ),
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
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'المجموع',
                          style: GoogleFonts.harmattan(
                            fontSize: 18,
                            color: AppColors.textSecond,
                          ),
                        ),
                        Text(
                          '${notifier.total.toInt()} ر.س',
                          style: GoogleFonts.harmattan(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blueSky,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TammButton(
                      label: AppStrings.checkout,
                      onPressed: () => context.push('/customer/checkout'),
                    ),
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
            height: 86,
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

