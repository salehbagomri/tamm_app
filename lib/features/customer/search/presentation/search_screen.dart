import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_shimmer.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../shared/providers/product_providers.dart';
import '../../../../shared/providers/service_providers.dart';
import '../../../../shared/models/product.dart';
import '../../../../shared/models/service_type.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _query = val.trim().toLowerCase();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);
    final servicesAsync = ref.watch(serviceTypesProvider);
    final featuredAsync = ref.watch(featuredProductsProvider);

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.bgSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          style: GoogleFonts.harmattan(fontSize: 16, color: context.colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'ابحث عن منتج أو خدمة...',
            hintStyle: GoogleFonts.harmattan(color: context.colors.textSecond),
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
        actions: [
          if (_searchCtrl.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close, color: context.colors.textSecond),
              onPressed: () {
                _searchCtrl.clear();
                _onSearchChanged('');
                setState(() {});
              },
            ),
        ],
      ),
      body: SafeArea(
        child: _query.isEmpty
            ? _buildSuggestions(featuredAsync)
            : _buildSearchResults(productsAsync, servicesAsync),
      ),
    );
  }

  Widget _buildSuggestions(AsyncValue<List<Product>> featuredAsync) {
    return featuredAsync.when(
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        final suggestions = products.take(4).toList();
        return ListView(
          padding: AppSpacing.pagePadding,
          children: [
            Text(
              'اقتراحات لك',
              style: GoogleFonts.harmattan(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...suggestions.map((p) => ListTile(
                  leading: Icon(Icons.trending_up, color: context.colors.textSecond),
                  title: Text(
                    p.name,
                    style: GoogleFonts.harmattan(fontSize: 16, color: context.colors.textPrimary),
                  ),
                  onTap: () => context.push('/customer/product/${p.id}'),
                )),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSearchResults(
    AsyncValue<List<Product>> productsAsync,
    AsyncValue<List<ServiceType>> servicesAsync,
  ) {
    return productsAsync.when(
      data: (products) {
        return servicesAsync.when(
          data: (services) {
            // Filter Products
            final filteredProducts = products.where((p) {
              return p.name.toLowerCase().contains(_query) ||
                  (p.brand?.toLowerCase().contains(_query) ?? false) ||
                  (p.description?.toLowerCase().contains(_query) ?? false);
            }).toList();

            // Filter Services
            final filteredServices = services.where((s) {
              return s.name.toLowerCase().contains(_query) ||
                  (s.description?.toLowerCase().contains(_query) ?? false);
            }).toList();

            if (filteredProducts.isEmpty && filteredServices.isEmpty) {
              return const TammEmptyState(
                icon: Icons.search_off,
                message: 'عذراً لا توجد نتائج للبحث.',
              );
            }

            return ListView(
              padding: AppSpacing.pagePadding,
              children: [
                if (filteredProducts.isNotEmpty) ...[
                  Text(
                    'منتجات 🛒',
                    style: GoogleFonts.harmattan(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...filteredProducts.map((p) => _ProductSearchResultItem(product: p)),
                  const SizedBox(height: 24),
                ],
                if (filteredServices.isNotEmpty) ...[
                  Text(
                    'خدمات 🔧',
                    style: GoogleFonts.harmattan(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...filteredServices.map((s) => _ServiceSearchResultItem(service: s)),
                  const SizedBox(height: 24),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _ProductSearchResultItem extends StatelessWidget {
  final Product product;
  const _ProductSearchResultItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      leading: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: context.colors.bgSurface,
          borderRadius: AppSpacing.radiusSm,
        ),
        child: product.imageUrl != null
            ? ClipRRect(
                borderRadius: AppSpacing.radiusSm,
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const TammShimmer(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: AppSpacing.radiusSm,
                  ),
                  errorWidget: (context, url, err) => Icon(
                    Icons.image,
                    color: context.colors.textFaint,
                  ),
                ),
              )
            : Icon(Icons.image, color: context.colors.textFaint),
      ),
      title: Text(
        product.name,
        style: GoogleFonts.harmattan(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: context.colors.textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        product.price != null ? '${product.price!.toInt()} ر.س' : 'غير محدد',
        style: GoogleFonts.harmattan(
          fontSize: 14,
          color: context.colors.blueSky,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: () => context.push('/customer/product/${product.id}'),
    );
  }
}

class _ServiceSearchResultItem extends StatelessWidget {
  final ServiceType service;
  const _ServiceSearchResultItem({required this.service});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      leading: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [context.colors.blueDark, context.colors.blueMid]),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.build_circle, color: context.colors.blueSky),
      ),
      title: Text(
        service.name,
        style: GoogleFonts.harmattan(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: context.colors.textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: service.description != null
          ? Text(
              service.description!,
              style: GoogleFonts.harmattan(
                fontSize: 14,
                color: context.colors.textSecond,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      onTap: () => context.push('/customer/service-detail/${service.id}'),
    );
  }
}
