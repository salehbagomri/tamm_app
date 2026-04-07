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

  // 3. Customer: Accept Quote — via RPC (SECURITY DEFINER يتجاوز RLS)
  Future<void> acceptQuote(String orderId) async {
    await _client.rpc('accept_quote', params: {'p_order_id': orderId});
  }

  // 4. Customer: Reject Quote — via RPC (SECURITY DEFINER يتجاوز RLS)
  Future<void> rejectQuote(String orderId, {String? reason}) async {
    await _client.rpc('reject_quote', params: {
      'p_order_id': orderId,
      'p_reason': reason ?? '',
    });
  }

  Future<List<Order>> getQuoteRequests() async {
    final res = await _client
        .from('orders')
        .select('*, items:order_items(*), profiles!customer_id(full_name, phone)')
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
