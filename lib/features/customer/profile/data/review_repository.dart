import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../shared/models/review.dart';

class ReviewRepository {
  final _client = Supabase.instance.client;

  Future<Review?> getReviewByOrderId(String orderId) async {
    try {
      final data = await _client
          .from('reviews')
          .select()
          .eq('order_id', orderId)
          .limit(1)
          .maybeSingle();
      return data == null ? null : Review.fromMap(data);
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<void> submitReview({
    required String orderId,
    required String customerId,
    String? technicianId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _client.from('reviews').insert({
        'order_id': orderId,
        'customer_id': customerId,
        if (technicianId != null) 'technician_id': technicianId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      });
    } catch (e) {
      if (e is AppException) rethrow;
      throw const ServerException(message: 'فشل في إرسال التقييم');
    }
  }
}
