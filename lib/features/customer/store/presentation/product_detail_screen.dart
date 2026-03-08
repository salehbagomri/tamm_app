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
import '../../../../shared/models/cart_item.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: const TammAppBar(title: 'تفاصيل المنتج'),
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
                    ? Image.network(p.imageUrl!, fit: BoxFit.cover)
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
                        label: AppStrings.addToCart,
                        icon: Icons.shopping_cart_outlined,
                        onPressed: () {
                          ref
                              .read(cartProvider.notifier)
                              .addItem(CartItem(product: p));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تمت الإضافة للسلة')),
                          );
                        },
                      )
                    else
                      TammButton(
                        label: AppStrings.requestQuote,
                        isOutlined: true,
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
