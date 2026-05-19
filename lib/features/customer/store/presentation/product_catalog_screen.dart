import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../shared/providers/product_providers.dart';
import '../widgets/product_card.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

/// نوع الفلتر المستخدم عند الفتح من الشاشة الرئيسية
enum CatalogFilter { bestSellers, deals }

class ProductCatalogScreen extends ConsumerWidget {
  final CatalogFilter filter;

  const ProductCatalogScreen({super.key, required this.filter});

  String get _title {
    switch (filter) {
      case CatalogFilter.bestSellers:
        return 'الأكثر طلباً 🔥';
      case CatalogFilter.deals:
        return 'عروض وأسعار مميزة 🏷️';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = switch (filter) {
      CatalogFilter.bestSellers => ref.watch(featuredProductsProvider),
      CatalogFilter.deals => ref.watch(dealsProvider),
    };

    final provider = switch (filter) {
      CatalogFilter.bestSellers => featuredProductsProvider,
      CatalogFilter.deals => dealsProvider,
    };

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.colors.textPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _title,
          style: AppTextStyles.sectionTitle(context.colors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.shopping_cart_outlined,
              color: context.colors.textPrimary,
            ),
            onPressed: () => context.push('/customer/cart'),
            tooltip: 'السلة',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: context.colors.bluePrimary,
          backgroundColor: context.colors.bgSurface,
          onRefresh: () async {
            ref.invalidate(provider);
            await ref.read(allProductsProvider.future);
          },
          child: productsAsync.when(
            loading: () => const TammLoading(),
            error: (e, _) => ErrorStateWidget(
              message: e is AppException
                  ? e.message
                  : 'حدث خطأ في تحميل المنتجات',
              onRetry: () => ref.invalidate(provider),
            ),
            data: (products) {
              if (products.isEmpty) {
                return ListView(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                    const TammEmptyState(
                      icon: Icons.inventory_2_outlined,
                      message: 'لا توجد منتجات في هذا القسم حالياً',
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        '${products.length} منتج',
                        style: AppTextStyles.bodySmall(
                          context.colors.textSecond,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: Responsive.gridColumns(context),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: Responsive.isDesktop(context)
                            ? 0.75
                            : 0.62,
                      ),
                      itemCount: products.length,
                      itemBuilder: (_, i) =>
                          ProductCard(product: products[i]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

