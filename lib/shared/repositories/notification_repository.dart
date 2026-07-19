import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/error_mapper.dart';

class NotificationRepository {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final userId = _client.auth.currentUser?.id;
    // ضيف أو غير مسجل → قائمة فارغة بدون crash
    if (userId == null) return [];
    try {
      return await _client
          .from('notifications')
          .select(
            'id, user_id, title, body, is_read, created_at, notification_type, order_id, data',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<void> markAsRead(String id) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<void> markAllRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  Future<void> notifyManagerReceiptUploaded({
    required String orderId,
    required String orderNumber,
  }) async {
    try {
      final managers = await _client
          .from('profiles')
          .select('id')
          .eq('role', 'manager')
          .limit(1);
      if (managers.isEmpty) return;
      final managerId = managers.first['id'] as String;
      await _client.from('notifications').insert({
        'user_id': managerId,
        'title': 'سند تحويل جديد',
        'body': 'قام العميل بإرفاق سند التحويل للطلب #$orderNumber',
        'notification_type': 'payment_receipt',
        'type': 'payment_receipt',
        'order_id': orderId,
        'is_read': false,
      });
    } catch (_) {
      // Non-critical — don't block the user
    }
  }

  Future<int> getUnreadCount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;
    try {
      final res = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false)
          .count(CountOption.exact);
      return res.count;
    } catch (e) {
      throw ErrorMapper.from(e);
    }
  }
}
