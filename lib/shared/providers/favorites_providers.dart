import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../repositories/favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (_) => FavoritesRepository(),
);

/// Set of favorited product IDs for the current user.
/// Not autoDispose — shared across ProductCards on the same screen.
final favoritedIdsProvider = FutureProvider<Set<String>>((ref) async {
  final repo = ref.read(favoritesRepositoryProvider);
  return repo.fetchFavoritedIds();
});

/// Full product list for MyFavoritesScreen.
final favoriteProductsProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.read(favoritesRepositoryProvider);
  return repo.fetchFavoriteProducts();
});
