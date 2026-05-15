import '../../../../core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../shared/providers/product_providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class ManageProductsScreen extends ConsumerWidget {
  const ManageProductsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider(null));
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.colors.bluePrimary,
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
                  Flexible(
                    child: Text(
                      'إدارة المنتجات',
                      style: AppTextStyles.h3(context.colors.textPrimary),
                    ),
                  ),
                  AppSpacing.hGapSm,
                  TextButton.icon(
                    onPressed: () => context.push('/manager/promotions'),
                    icon: Icon(
                      Icons.campaign_outlined,
                      size: 18,
                      color: context.colors.blueSky,
                    ),
                    label: Text(
                      'العروض',
                      style: AppTextStyles.body(context.colors.textPrimary),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapMd,
              Expanded(
                child: productsAsync.when(
                  data: (products) {
                    if (products.isEmpty) {
                      return const TammEmptyState(
                        icon: Icons.inventory_outlined,
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
                                decoration: BoxDecoration(
                                  color: context.colors.bgSurface2,
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
                                    : Icon(
                                        Icons.image_outlined,
                                        color: context.colors.textFaint,
                                      ),
                              ),
                              AppSpacing.hGapSm2,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: AppTextStyles.body(
                                        context.colors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      p.categoryLabel,
                                      style: AppTextStyles.bodySmall(
                                        context.colors.textSecond,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        if (p.isFeatured)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              left: 4,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: context.colors.warning,
                                              borderRadius: AppSpacing.radiusXs,
                                            ),
                                            child: Text(
                                              'مميز ⭐',
                                              style:
                                                  AppTextStyles.badge(
                                                    Colors.white,
                                                  ).copyWith(
                                                    fontWeight:
                                                        AppTextStyles.bold,
                                                  ),
                                            ),
                                          ),
                                        if (p.hasDiscount)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: context.colors.error,
                                              borderRadius: AppSpacing.radiusXs,
                                            ),
                                            child: Text(
                                              'خصم ${p.discountPercentage}%',
                                              style:
                                                  AppTextStyles.badge(
                                                    Colors.white,
                                                  ).copyWith(
                                                    fontWeight:
                                                        AppTextStyles.bold,
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
                                      style:
                                          AppTextStyles.caption(
                                            context.colors.textSecond,
                                          ).copyWith(
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                    ),
                                  Text(
                                    p.price != null
                                        ? '${p.price!.toInt()} ر.س'
                                        : 'عرض سعر',
                                    style: AppTextStyles.body(
                                      context.colors.textPrimary,
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
                  error: (e, _) => ErrorStateWidget(
                    message: e is AppException
                        ? e.message
                        : 'حدث خطأ في تحميل المنتجات',
                    onRetry: () => ref.invalidate(productsProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
