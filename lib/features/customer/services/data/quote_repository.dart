import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/order.dart';

final quoteRepositoryProvider = Provider((ref) => QuoteRepository());

class QuoteRepository {
  final _client = Supabase.instance.client;

  // 1. Manager: Upload attachment (PDF/image) to Supabase Storage
  Future<String?> uploadAttachment({
    required String orderId,
    required File file,
  }) async {
    final ext = file.path.split('.').last.toLowerCase();
    final path = 'quotes/$orderId/attachment_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from('quote-attachments').upload(path, file);

    final publicUrl = _client.storage.from('quote-attachments').getPublicUrl(path);
    return publicUrl;
  }

  // 2. Manager: Send Quote to Customer (with optional attachment)
  Future<void> sendQuote({
    required String orderId,
    required double price,
    required String details,
    String? duration,
    String? attachmentUrl,
  }) async {
    final updates = <String, dynamic>{
      'quote_price': price,
      'quote_details': details,
      'quote_duration': duration,
      'quote_status': 'sent',
      'quote_sent_at': DateTime.now().toIso8601String(),
    };

    if (attachmentUrl != null && attachmentUrl.isNotEmpty) {
      updates['quote_attachment_url'] = attachmentUrl;
    }

    await _client.from('orders').update(updates).eq('id', orderId);
  }

  // 3. Customer: Accept Quote
  Future<void> acceptQuote(String orderId) async {
    // جلب السعر أولاً
    final order = await _client.from('orders').select('quote_price').eq('id', orderId).single();
    final price = (order['quote_price'] as num?)?.toDouble() ?? 0;
    
    await _client.from('orders').update({
      'quote_status': 'accepted',
      'quote_responded_at': DateTime.now().toIso8601String(),
      'status': 'confirmed',
      'total_amount': price, // ← تحديث المجموع
    }).eq('id', orderId);
  }

  // 4. Customer: Reject Quote
  Future<void> rejectQuote(String orderId, {String? reason}) async {
    await _client.from('orders').update({
      'quote_status': 'rejected',
      'quote_responded_at': DateTime.now().toIso8601String(),
      // لا نغير status - يبقى الطلب مفتوح للمدير ليرسل عرض جديد
      'rejection_reason': reason,
    }).eq('id', orderId);
  }

  // 5. Manager: Get all Quote Requests
  Future<List<Order>> getQuoteRequests() async {
    final res = await _client
        .from('orders')
        .select('*, items:order_items(*), profiles!orders_customer_id_fkey(*)')
        .eq('order_type', 'quote_request')
        .order('created_at', ascending: false);

    return (res as List).map((e) => Order.fromMap(e)).toList();
  }

  // 6. Manager: Resend Quote after rejection
  Future<void> resendQuote({
    required String orderId,
    required double price,
    required String details,
    String? duration,
    String? attachmentUrl,
  }) async {
    final updates = <String, dynamic>{
      'quote_price': price,
      'quote_details': details,
      'quote_duration': duration,
      'quote_status': 'sent',
      'quote_sent_at': DateTime.now().toIso8601String(),
      'rejection_reason': null, // مسح سبب الرفض السابق
      'quote_responded_at': null,
    };
    if (attachmentUrl != null) updates['quote_attachment_url'] = attachmentUrl;
    await _client.from('orders').update(updates).eq('id', orderId);
  }
}
