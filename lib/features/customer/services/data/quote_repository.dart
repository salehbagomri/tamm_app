import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/order.dart';

final quoteRepositoryProvider = Provider((ref) => QuoteRepository());

class QuoteRepository {
  final _client = Supabase.instance.client;

  // 1. Manager: Send Quote to Customer
  Future<void> sendQuote({
    required String orderId,
    required double price,
    required String details,
    String? duration,
  }) async {
    await _client.from('orders').update({
      'quote_price': price,
      'quote_details': details,
      'quote_duration': duration,
      'quote_status': 'sent',
      'quote_sent_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  // 2. Customer: Accept Quote
  Future<void> acceptQuote(String orderId) async {
    await _client.from('orders').update({
      'quote_status': 'accepted',
      'quote_responded_at': DateTime.now().toIso8601String(),
      'status': 'confirmed',
    }).eq('id', orderId);
  }

  // 3. Customer: Reject Quote
  Future<void> rejectQuote(String orderId, {String? reason}) async {
    final updates = <String, dynamic>{
      'quote_status': 'rejected',
      'quote_responded_at': DateTime.now().toIso8601String(),
      'status': 'cancelled',
    };
    if (reason != null && reason.isNotEmpty) {
      updates['rejection_reason'] = reason;
    }
    
    await _client.from('orders').update(updates).eq('id', orderId);
  }

  // 4. Manager: Get all Quote Requests
  Future<List<Order>> getQuoteRequests() async {
    final res = await _client
        .from('orders')
        .select('*, items:order_items(*)')
        .eq('order_type', 'quote_request')
        .order('created_at', ascending: false);

    return (res as List).map((e) => Order.fromMap(e)).toList();
  }
}
