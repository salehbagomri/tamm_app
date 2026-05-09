import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/product_repository.dart';
import '../models/product.dart';

// Filter state model for the store
enum ProductSort { none, priceAsc, priceDesc, newest }

class StoreFilterState {
  final String? category;
  final String searchQuery;
  final ProductSort sort;
  final bool dealsOnly;
  final bool featuredOnly;

  const StoreFilterState({
    this.category,
    this.searchQuery = '',
    this.sort = ProductSort.none,
    this.dealsOnly = false,
    this.featuredOnly = false,
  });

  StoreFilterState copyWith({
    String? category,
    bool clearCategory = false,
    String? searchQuery,
    ProductSort? sort,
    bool? dealsOnly,
    bool? featuredOnly,
  }) {
    return StoreFilterState(
      category: clearCategory ? null : (category ?? this.category),
      searchQuery: searchQuery ?? this.searchQuery,
      sort: sort ?? this.sort,
      dealsOnly: dealsOnly ?? this.dealsOnly,
      featuredOnly: featuredOnly ?? this.featuredOnly,
    );
  }
}

final storeFilterProvider = StateProvider<StoreFilterState>(
  (ref) => const StoreFilterState(),
);

final productRepositoryProvider = Provider((ref) => ProductRepository());

// Base provider to fetch and cache all products
final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.read(productRepositoryProvider).getProducts();
});

// Calculate product counts per category
final categoryCountsProvider = Provider<Map<String?, int>>((ref) {
  final productsOpt = ref.watch(allProductsProvider).valueOrNull;
  if (productsOpt == null) return {};

  final Map<String?, int> counts = {null: productsOpt.length}; // Total count
  for (final p in productsOpt) {
    counts[p.category] = (counts[p.category] ?? 0) + 1;
    // Add deals count
    if (p.hasDiscount) {
      counts['deals'] = (counts['deals'] ?? 0) + 1;
    }
  }
  return counts;
});

// The filtered products provider that the store consumes
final storeFilteredProductsProvider = Provider<AsyncValue<List<Product>>>((
  ref,
) {
  final asyncProducts = ref.watch(allProductsProvider);
  final filter = ref.watch(storeFilterProvider);

  return asyncProducts.whenData((products) {
    var filtered = products.toList();

    // 1. Filter by category
    if (filter.category != null && filter.category != 'deals') {
      filtered = filtered.where((p) => p.category == filter.category).toList();
    } else if (filter.category == 'deals') {
      filtered = filtered.where((p) => p.hasDiscount).toList();
    }

    // 2. Filter by search query
    if (filter.searchQuery.isNotEmpty) {
      final q = filter.searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                (p.brand?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }

    // 3. Filter by deals / featured toggles
    if (filter.dealsOnly) {
      filtered = filtered.where((p) => p.hasDiscount).toList();
    }
    if (filter.featuredOnly) {
      filtered = filtered.where((p) => p.isFeatured).toList();
    }

    // 4. Sort
    switch (filter.sort) {
      case ProductSort.priceAsc:
        filtered.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
      case ProductSort.priceDesc:
        filtered.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
      case ProductSort.newest:
      case ProductSort.none:
        break; // Default sort logic is what we get from DB
    }

    return filtered;
  });
});

final productsProvider = FutureProvider.family<List<Product>, String?>((
  ref,
  category,
) async {
  return ref.read(productRepositoryProvider).getProducts(category: category);
});

final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  final all = await ref.watch(allProductsProvider.future);
  return all.where((p) => p.isFeatured).toList();
});

final productDetailProvider = FutureProvider.family<Product, String>((
  ref,
  id,
) async {
  return ref.read(productRepositoryProvider).getProduct(id);
});

final dealsProvider = FutureProvider<List<Product>>((ref) async {
  final all = await ref.watch(allProductsProvider.future);
  return all.where((p) => p.hasDiscount).toList();
});
