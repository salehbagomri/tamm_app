import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';

class OrderRepository {
  final _client = Supabase.instance.client;

  Future<List<Order>> getMyOrders() async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('orders')
        .select('*, order_items(*)')
        .eq('customer_id', userId)
        .order('created_at', ascending: false);
    return data.map((e) => Order.fromMap(e)).toList();
  }

  Future<List<Order>> getAllOrders({String? status}) async {
    var query = _client
        .from('orders')
        .select('*, order_items(*), profiles!customer_id(full_name, phone)');
    if (status != null) query = query.eq('status', status);
    final data = await query.order('created_at', ascending: false);
    return data.map((e) => Order.fromMap(e)).toList();
  }

  Future<Order> getOrder(String id) async {
    final data = await _client
        .from('orders')
        .select('*, order_items(*)')
        .eq('id', id)
        .single();
    return Order.fromMap(data);
  }

  Future<String> createOrder({
    required String orderType,
    required String address,
    required double total,
    DateTime? preferredDate,
    String? timeSlot,
    String? notes,
    bool includeInstall = false,
    required List<Map<String, dynamic>> items,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final orderData = await _client
        .from('orders')
        .insert({
          'customer_id': userId,
          'order_type': orderType,
          'total_amount': total,
          'address': address,
          'preferred_date': preferredDate?.toIso8601String().split('T')[0],
          'preferred_time_slot': timeSlot,
          'notes': notes,
          'include_installation': includeInstall,
        })
        .select()
        .single();

    final orderId = orderData['id'] as String;
    for (final item in items) {
      item['order_id'] = orderId;
      await _client.from('order_items').insert(item);
    }
    return orderId;
  }

  Future<void> updateOrderStatus(String id, String status) async {
    await _client.from('orders').update({'status': status}).eq('id', id);
  }
}
