import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../shared/providers/product_providers.dart';
import '../../../../shared/providers/order_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../shared/models/cart_item.dart';
import 'buy_install_sheet.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
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
                    backgroundColor: AppColors.error,
                    child: const Icon(Icons.shopping_cart_outlined, color: AppColors.textPrimary),
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
        data: (p) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 250,
                width: double.infinity,
                color: AppColors.bgSurface2,
                child: p.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: p.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const Icon(
                          Icons.image,
                          size: 80,
                          color: AppColors.textFaint,
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.image,
                          size: 80,
                          color: AppColors.textFaint,
                        ),
                      ),
              ),
              Padding(
                padding: AppSpacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    if (p.brand != null)
                      Text(
                        p.brand!,
                        style: GoogleFonts.harmattan(
                          fontSize: 14,
                          color: AppColors.textSecond,
                        ),
                      ),
                    Text(
                      p.name,
                      style: GoogleFonts.harmattan(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.price != null
                          ? '${p.price!.toInt()} ريال'
                          : AppStrings.requestQuote,
                      style: GoogleFonts.harmattan(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blueSky,
                      ),
                    ),
                    if (p.description != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        p.description!,
                        style: GoogleFonts.harmattan(
                          fontSize: 16,
                          color: AppColors.textSecond,
                          height: 1.6,
                        ),
                      ),
                    ],
                    if (p.specs.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'المواصفات',
                        style: GoogleFonts.harmattan(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...p.specs.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Text(
                                '${e.key}: ',
                                style: GoogleFonts.harmattan(
                                  fontSize: 14,
                                  color: AppColors.textSecond,
                                ),
                              ),
                              Text(
                                '${e.value}',
                                style: GoogleFonts.harmattan(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    if (p.price != null)
                      TammButton(
                        label: p.requiresInstallation ? 'اشترِ وركّب / أضف للسلة' : AppStrings.addToCart,
                        icon: Icons.shopping_cart_outlined,
                        onPressed: () async {
                          if (p.requiresInstallation) {
                            final result = await showModalBottomSheet<bool>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const BuyInstallSheet(),
                            );
                            if (result == null) return; // User cancelled
                            // result holds whether user wants installation, handled in checkout later
                          }

                          try {
                            // We use ref.read to interact with our async cart provider
                            final cartNotifier = ref.read(cartProvider.notifier);
                            await cartNotifier.addItem(CartItem(product: p));
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تمت الإضافة للسلة')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('تعذرت الإضافة للسلة: \$e')),
                              );
                            }
                          }
                        },
                      )
                    else
                      TammButton(
                        label: AppStrings.requestQuote,
                        type: TammButtonType.secondary,
                        onPressed: () => context.push('/customer/services'),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const TammLoading(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
