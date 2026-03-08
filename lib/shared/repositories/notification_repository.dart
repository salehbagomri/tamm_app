import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepository {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final userId = _client.auth.currentUser!.id;
    return await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
  }

  Future<void> markAsRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> markAllRead() async {
    final userId = _client.auth.currentUser!.id;
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  Future<int> getUnreadCount() async {
    final userId = _client.auth.currentUser!.id;
    final res = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .eq('is_read', false)
        .count(CountOption.exact);
    return res.count;
  }
}
