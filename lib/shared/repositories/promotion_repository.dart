import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/promotion.dart';

class PromotionRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Promotion>> getActivePromotions() async {
    final response = await _client
        .from('promotions')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);
    return (response as List).map((m) => Promotion.fromMap(m)).toList();
  }

  Future<List<Promotion>> getAllPromotions() async {
    final response = await _client
        .from('promotions')
        .select()
        .order('sort_order', ascending: true);
    return (response as List).map((m) => Promotion.fromMap(m)).toList();
  }

  Future<void> createPromotion(Promotion promotion) async {
    await _client.from('promotions').insert(promotion.toMap());
  }

  Future<void> updatePromotion(String id, Map<String, dynamic> data) async {
    await _client.from('promotions').update(data).eq('id', id);
  }

  Future<void> deletePromotion(String id) async {
    await _client.from('promotions').delete().eq('id', id);
  }
}
