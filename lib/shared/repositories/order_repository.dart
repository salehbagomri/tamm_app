import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';

class OrderRepository {
  final _client = Supabase.instance.client;

  Future<List<Order>> getMyOrders() async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('orders')
        .select(
          '*, order_items(*), assignments(technician_notes, technicians(profiles(full_name)))',
        )
        .eq('customer_id', userId)
        .order('created_at', ascending: false);
    return data.map((e) => Order.fromMap(e)).toList();
  }

  Future<List<Order>> getAllOrders({String? status}) async {
    var query = _client
        .from('orders')
        .select(
          '*, order_items(*), profiles!customer_id(full_name, phone), assignments(technician_notes, technicians(profiles(full_name)))',
        );
    if (status != null) query = query.eq('status', status);
    final data = await query.order('created_at', ascending: false);
    return data.map((e) => Order.fromMap(e)).toList();
  }

  Future<Order> getOrder(String id) async {
    final data = await _client
        .from('orders')
        .select(
          '*, order_items(*), profiles!customer_id(full_name, phone), assignments(technician_notes, technicians(profiles(full_name)))',
        )
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
    String? scheduledPeriod,
    String? scheduledHour,
    String? quoteStatus,
    double? latitude,
    double? longitude,
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
          'scheduled_period': scheduledPeriod,
          'scheduled_hour': scheduledHour,
          'quote_status': quoteStatus,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
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

  Future<void> updateQuoteStatus(String orderId, String status, {String? rejectionReason}) async {
    final updates = <String, dynamic>{
      'quote_status': status,
      'quote_responded_at': DateTime.now().toIso8601String(),
    };
    if (status == 'accepted') {
      updates['status'] = 'confirmed';
    } else if (status == 'rejected') {
      updates['status'] = 'cancelled';
      if (rejectionReason != null) {
        updates['rejection_reason'] = rejectionReason;
      }
    }
    await _client.from('orders').update(updates).eq('id', orderId);
  }
}
