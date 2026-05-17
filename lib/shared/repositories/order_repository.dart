import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/errors/app_exception.dart';

class OrderRepository {
  final _client = Supabase.instance.client;

  Future<List<Order>> getMyOrders() async {
    try {
      final userId = _client.auth.currentUser!.id;
      final data = await _client
          .from('orders')
          .select(
            '*, order_items(*), assignments(technician_notes, technicians(profiles(full_name)))',
          )
          .eq('customer_id', userId)
          .order('created_at', ascending: false);
      return data.map((e) => Order.fromMap(e)).toList();
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<List<Order>> getAllOrders({String? status}) async {
    try {
      var query = _client
          .from('orders')
          .select(
            '*, order_items(*), profiles!customer_id(full_name, phone), assignments(technician_notes, technicians(profiles(full_name)))',
          );
      if (status != null) query = query.eq('status', status);
      final data = await query.order('created_at', ascending: false);
      return data.map((e) => Order.fromMap(e)).toList();
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<Order> getOrder(String id) async {
    try {
      final data = await _client
          .from('orders')
          .select(
            '*, order_items(*), profiles!customer_id(full_name, phone), assignments(technician_notes, technicians(profiles(full_name)))',
          )
          .eq('id', id)
          .single();
      return Order.fromMap(data);
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<({String id, String orderNumber})> createOrder({
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
    String? city,
    double? latitude,
    double? longitude,
    String paymentType = 'cash',
    String? paymentMethodId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final userId = _client.auth.currentUser!.id;
      final payload = {
        'customer_id': userId,
        'order_type': orderType,
        'total_amount': total,
        'address': address,
        'preferred_date': preferredDate?.toIso8601String().split('T')[0],
        'preferred_time_slot': timeSlot ?? 'صباحاً',
        'notes': notes,
        'include_installation': includeInstall,
        'scheduled_period': scheduledPeriod,
        'scheduled_hour': scheduledHour,
        'payment_type': paymentType,
        if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
        if (quoteStatus != null) 'quote_status': quoteStatus,
        if (city != null) 'city': city,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };
      final orderData = await _client
          .from('orders')
          .insert(payload)
          .select()
          .single();

      final orderId = orderData['id'] as String;
      final orderNumber = orderData['order_number'] as String;

      // إدخال عناصر الطلب — try/catch مستقل برسالة مخصصة
      try {
        for (final item in items) {
          item['order_id'] = orderId;
          await _client.from('order_items').insert(item);
        }
      } catch (e) {
        throw const ServerException(
          message: 'فشل في إتمام الطلب، يرجى المحاولة مجدداً',
        );
      }

      return (id: orderId, orderNumber: orderNumber);
    } catch (e) {
      // لا تُغلِّف AppException مرة أخرى
      if (e is AppException) rethrow;
      throw ErrorMapper.from(e);
    }
  }

  Future<void> updateOrderStatus(String id, String status) async {
    try {
      await _client.from('orders').update({'status': status}).eq('id', id);
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<void> updateQuoteStatus(
    String orderId,
    String status, {
    String? rejectionReason,
  }) async {
    try {
      final updates = <String, dynamic>{
        'quote_status': status,
        'quote_responded_at': DateTime.now().toIso8601String(),
      };
      if (status == 'accepted') {
        final order = await _client
            .from('orders')
            .select('quote_price')
            .eq('id', orderId)
            .single();
        final price = (order['quote_price'] as num?)?.toDouble() ?? 0;
        updates['status'] = 'confirmed';
        updates['total_amount'] = price;
      } else if (status == 'rejected') {
        if (rejectionReason != null) {
          updates['rejection_reason'] = rejectionReason;
        }
      }
      await _client.from('orders').update(updates).eq('id', orderId);
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<String> uploadReceipt({
    required String orderId,
    required Uint8List bytes,
  }) async {
    try {
      final path =
          'receipts/$orderId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _client.storage.from('receipts').uploadBinary(path, bytes);
      final url = _client.storage.from('receipts').getPublicUrl(path);
      await _client
          .from('orders')
          .update({'receipt_url': url})
          .eq('id', orderId);
      return url;
    } catch (e) {
      if (e is AppException) rethrow;
      throw const ServerException(
        message: 'فشل في رفع الصورة، تحقق من اتصالك',
      );
    }
  }
}
