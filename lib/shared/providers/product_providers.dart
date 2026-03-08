import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/product_repository.dart';
import '../models/product.dart';

final productRepositoryProvider = Provider((ref) => ProductRepository());

final productsProvider = FutureProvider.family<List<Product>, String?>((
  ref,
  category,
) async {
  return ref.read(productRepositoryProvider).getProducts(category: category);
});

final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.read(productRepositoryProvider).getProducts(featuredOnly: true);
});

final productDetailProvider = FutureProvider.family<Product, String>((
  ref,
  id,
) async {
  return ref.read(productRepositoryProvider).getProduct(id);
});
