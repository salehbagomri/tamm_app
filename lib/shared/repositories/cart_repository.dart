import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartRepository {
  final _client = Supabase.instance.client;

  Future<List<CartItem>> getCartItems() async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('cart_items')
        .select('*, products(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    print('DEBUG: Fetched cart data from Supabase: \$data');

    return data.map((e) {
      final productData = e['products'] as Map<String, dynamic>;
      final product = Product.fromMap(productData);
      return CartItem(product: product, quantity: e['quantity'] as int);
    }).toList();
  }

  Future<void> addToCart(String productId, int quantity) async {
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
          .update({'quantity': currentQty + quantity})
          .eq('user_id', userId)
          .eq('product_id', productId);
    } else {
      await _client.from('cart_items').insert({
        'user_id': userId,
        'product_id': productId,
        'quantity': quantity,
      });
    }
  }

  Future<void> updateQuantity(String productId, int quantity) async {
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
  }

  Future<void> removeItem(String productId) async {
    final userId = _client.auth.currentUser!.id;
    await _client
        .from('cart_items')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);
  }

  Future<void> clearCart() async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('cart_items').delete().eq('user_id', userId);
  }

  Stream<int> getCartCount() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value(0);
    
    return _client
        .from('cart_items')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.length);
  }
}
