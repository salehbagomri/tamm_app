import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../shared/providers/product_providers.dart';

class ManageProductsScreen extends ConsumerWidget {
  const ManageProductsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider(null));
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.bluePrimary,
        child: const Icon(Icons.add),
        onPressed: () => context.push('/manager/product/form'),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'إدارة المنتجات',
                    style: GoogleFonts.harmattan(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/manager/promotions'),
                    icon: const Icon(Icons.campaign, size: 20),
                    label: Text(
                      'إدارة العروض',
                      style: GoogleFonts.harmattan(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blueSky.withValues(alpha: 0.1),
                      foregroundColor: AppColors.blueSky,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: productsAsync.when(
                  data: (products) {
                    if (products.isEmpty) {
                      return const TammEmptyState(
                        icon: Icons.inventory,
                        message: 'لا توجد منتجات',
                      );
                    }
                    return ListView.separated(
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final p = products[i];
                        return TammCard(
                          onTap: () => context.push(
                            '/manager/product/form',
                            extra: p.id,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
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
                                      p.name,
                                      style: GoogleFonts.harmattan(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      p.categoryLabel,
                                      style: GoogleFonts.harmattan(
                                        fontSize: 14,
                                        color: AppColors.textSecond,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        if (p.isFeatured)
                                          Container(
                                            margin: const EdgeInsets.only(left: 4),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.warning,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'مميز ⭐',
                                              style: GoogleFonts.harmattan(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        if (p.hasDiscount)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.error,
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
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (p.hasDiscount)
                                    Text(
                                      '${p.oldPrice!.toInt()}',
                                      style: GoogleFonts.harmattan(
                                        fontSize: 12,
                                        color: AppColors.textSecond,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  Text(
                                    p.price != null
                                        ? '${p.price!.toInt()} ر.س'
                                        : 'عرض سعر',
                                    style: GoogleFonts.harmattan(
                                      color: AppColors.blueSky,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const TammLoading(),
                  error: (e, _) =>
                      TammEmptyState(icon: Icons.error_outline, message: '$e'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
