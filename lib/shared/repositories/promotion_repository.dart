import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/promotion.dart';
import '../../core/errors/error_mapper.dart';

class PromotionRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Promotion>> getActivePromotions() async {
    try {
      final response = await _client
          .from('promotions')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      return (response as List).map((m) => Promotion.fromMap(m)).toList();
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<List<Promotion>> getAllPromotions() async {
    try {
      final response = await _client
          .from('promotions')
          .select()
          .order('sort_order', ascending: true);
      return (response as List).map((m) => Promotion.fromMap(m)).toList();
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<void> createPromotion(Promotion promotion) async {
    try {
      await _client.from('promotions').insert(promotion.toMap());
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<void> updatePromotion(String id, Map<String, dynamic> data) async {
    try {
      await _client.from('promotions').update(data).eq('id', id);
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<void> deletePromotion(String id) async {
    try {
      await _client.from('promotions').delete().eq('id', id);
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }
}
