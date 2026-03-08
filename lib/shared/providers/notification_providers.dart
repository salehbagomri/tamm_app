import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider(
  (ref) => NotificationRepository(),
);

final notificationsProvider =
    StateNotifierProvider<
      NotificationNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return NotificationNotifier(ref.read(notificationRepositoryProvider));
    });

class NotificationNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final NotificationRepository _repo;
  StreamSubscription? _subscription;

  NotificationNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
    _listenRealtime();
  }

  Future<void> _load() async {
    try {
      final data = await _repo.getNotifications();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _listenRealtime() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _subscription = Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .listen((data) {
          state = AsyncValue.data(data);
        });
  }

  Future<void> markAsRead(String id) async {
    await _repo.markAsRead(id);
    _load();
  }

  Future<void> markAllRead() async {
    await _repo.markAllRead();
    _load();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final unreadCountProvider = Provider<int>((ref) {
  final notifsAsync = ref.watch(notificationsProvider);
  return notifsAsync.maybeWhen(
    data: (list) => list.where((n) => n['is_read'] == false).length,
    orElse: () => 0,
  );
});
