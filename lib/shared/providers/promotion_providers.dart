import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/promotion_repository.dart';
import '../models/promotion.dart';

final promotionRepositoryProvider = Provider((ref) => PromotionRepository());

final activePromotionsProvider = FutureProvider<List<Promotion>>((ref) async {
  return ref.read(promotionRepositoryProvider).getActivePromotions();
});

final allPromotionsProvider = FutureProvider<List<Promotion>>((ref) async {
  return ref.read(promotionRepositoryProvider).getAllPromotions();
});
