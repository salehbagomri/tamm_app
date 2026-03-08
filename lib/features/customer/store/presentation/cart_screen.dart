import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../shared/providers/order_providers.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: const TammAppBar(title: 'السلة'),
      body: cart.isEmpty
          ? const TammEmptyState(
              icon: Icons.shopping_cart_outlined,
              message: 'السلة فارغة',
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: AppSpacing.pagePadding,
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final item = cart[i];
                      return Container(
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
                              decoration: BoxDecoration(
                                color: AppColors.bgSurface2,
                                borderRadius: AppSpacing.radiusSm,
                              ),
                              child: item.product.imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: AppSpacing.radiusSm,
                                      child: Image.network(
                                        item.product.imageUrl!,
                                        fit: BoxFit.cover,
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
                                    '${item.total.toInt()} ريال',
                                    style: GoogleFonts.harmattan(
                                      fontSize: 14,
                                      color: AppColors.blueSky,
                                      fontWeight: FontWeight.w700,
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
                            '${notifier.total.toInt()} ريال',
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
            ),
    );
  }
}
