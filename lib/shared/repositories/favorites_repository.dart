import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_mapper.dart';
import '../models/product.dart';

class FavoritesRepository {
  final SupabaseClient _db = Supabase.instance.client;

  String get _userId {
    final id = _db.auth.currentUser?.id;
    if (id == null) throw const AuthException();
    return id;
  }

  /// Returns the set of product IDs the user has favorited.
  Future<Set<String>> fetchFavoritedIds() async {
    try {
      final rows = await _db
          .from('favorites')
          .select('product_id')
          .eq('user_id', _userId);
      return {for (final r in rows) r['product_id'] as String};
    } catch (e) {
      if (e is AppException) rethrow;
      throw ErrorMapper.from(e);
    }
  }

  /// Fetches the full product data for all favorited products.
  Future<List<Product>> fetchFavoriteProducts() async {
    try {
      final rows = await _db
          .from('favorites')
          .select('products(*)')
          .eq('user_id', _userId)
          .order('created_at', ascending: false);
      return rows
          .map((r) => Product.fromMap(r['products'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ErrorMapper.from(e);
    }
  }

  Future<void> add(String productId) async {
    try {
      await _db.from('favorites').insert({
        'user_id': _userId,
        'product_id': productId,
      });
    } catch (e) {
      if (e is AppException) rethrow;
      throw ErrorMapper.from(e);
    }
  }

  Future<void> remove(String productId) async {
    try {
      await _db
          .from('favorites')
          .delete()
          .eq('user_id', _userId)
          .eq('product_id', productId);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ErrorMapper.from(e);
    }
  }
}
