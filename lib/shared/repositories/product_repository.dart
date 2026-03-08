import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductRepository {
  final _client = Supabase.instance.client;

  Future<List<Product>> getProducts({
    String? category,
    bool? featuredOnly,
  }) async {
    var query = _client.from('products').select().eq('is_available', true);
    if (category != null) query = query.eq('category', category);
    if (featuredOnly == true) query = query.eq('is_featured', true);
    final data = await query.order('sort_order');
    return data.map((e) => Product.fromMap(e)).toList();
  }

  Future<Product> getProduct(String id) async {
    final data = await _client.from('products').select().eq('id', id).single();
    return Product.fromMap(data);
  }

  Future<void> createProduct(Product p) async =>
      await _client.from('products').insert(p.toMap());
  Future<void> updateProduct(String id, Map<String, dynamic> data) async =>
      await _client.from('products').update(data).eq('id', id);
  Future<void> deleteProduct(String id) async =>
      await _client.from('products').delete().eq('id', id);
}
