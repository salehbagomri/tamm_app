import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/providers/favorites_providers.dart';
import '../../store/widgets/product_card.dart';

class MyFavoritesScreen extends ConsumerWidget {
  const MyFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProducts = ref.watch(favoriteProductsProvider);

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.bgPrimary,
        elevation: 0,
        title: Text(
          'مفضلتي',
          style: AppTextStyles.cardTitle(context.colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: asyncProducts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: context.colors.error, size: 40),
              AppSpacing.gapSm,
              Text(
                e is AppException ? e.message : 'حدث خطأ في تحميل المفضلة',
                style: AppTextStyles.body(context.colors.textSecond),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapMd,
              TextButton(
                onPressed: () => ref.invalidate(favoriteProductsProvider),
                child: Text(
                  'إعادة المحاولة',
                  style: AppTextStyles.body(context.colors.bluePrimary),
                ),
              ),
            ],
          ),
        ),
        data: (products) => products.isEmpty
            ? _EmptyFavorites()
            : GridView.builder(
                padding: AppSpacing.pagePadding,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.sm2,
                  crossAxisSpacing: AppSpacing.sm2,
                  childAspectRatio: 0.68,
                ),
                itemCount: products.length,
                itemBuilder: (_, i) => ProductCard(product: products[i]),
              ),
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_outline_rounded,
              size: 64,
              color: context.colors.textFaint,
            ),
            AppSpacing.gapMd,
            Text(
              'لا توجد منتجات في المفضلة',
              style: AppTextStyles.cardTitle(context.colors.textPrimary),
            ),
            AppSpacing.gapSm,
            Text(
              'اضغط على القلب على أي منتج لحفظه هنا',
              style: AppTextStyles.bodySmall(context.colors.textSecond),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
