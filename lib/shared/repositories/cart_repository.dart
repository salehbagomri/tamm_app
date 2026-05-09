import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../../core/errors/error_mapper.dart';

class CartRepository {
  final _client = Supabase.instance.client;

  Future<List<CartItem>> getCartItems() async {
    try {
      final userId = _client.auth.currentUser!.id;
      final data = await _client
          .from('cart_items')
          .select('*, products(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      return data.map((e) {
        final productData = e['products'] as Map<String, dynamic>;
        final product = Product.fromMap(productData);
        return CartItem(
          product: product,
          quantity: e['quantity'] as int,
          includeInstallation: e['include_installation'] ?? false,
        );
      }).toList();
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<void> addToCart(
    String productId,
    int quantity,
    bool includeInstallation,
  ) async {
    try {
      final userId = _client.auth.currentUser!.id;

      // Check if it already exists to upsert
      final existing = await _client
          .from('cart_items')
          .select('quantity')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      if (existing != null) {
        final currentQty = existing['quantity'] as int;
        await _client
            .from('cart_items')
            .update({
              'quantity': currentQty + quantity,
              'include_installation':
                  includeInstallation, // Update preference if it changes
            })
            .eq('user_id', userId)
            .eq('product_id', productId);
      } else {
        await _client.from('cart_items').insert({
          'user_id': userId,
          'product_id': productId,
          'quantity': quantity,
          'include_installation': includeInstallation,
        });
      }
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    try {
      final userId = _client.auth.currentUser!.id;
      if (quantity <= 0) {
        await removeItem(productId);
        return;
      }
      await _client
          .from('cart_items')
          .update({'quantity': quantity})
          .eq('user_id', userId)
          .eq('product_id', productId);
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<void> removeItem(String productId) async {
    try {
      final userId = _client.auth.currentUser!.id;
      await _client
          .from('cart_items')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', productId);
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<void> clearCart() async {
    try {
      final userId = _client.auth.currentUser!.id;
      await _client.from('cart_items').delete().eq('user_id', userId);
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// Stream — يستخدم handleError بدلاً من try/catch
  Stream<int> getCartCount() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value(0);

    return _client
        .from('cart_items')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.length)
        .handleError((e) => 0);
  }
}
