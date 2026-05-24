import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/order_repository.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../repositories/cart_repository.dart';
import '../repositories/local_cart_repository.dart';

final orderRepositoryProvider = Provider((ref) => OrderRepository());
final cartRepositoryProvider = Provider((ref) => CartRepository());

final myOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  return ref.read(orderRepositoryProvider).getMyOrders();
});

final allOrdersProvider = FutureProvider.autoDispose
    .family<List<Order>, String?>((ref, status) async {
      return ref.read(orderRepositoryProvider).getAllOrders(status: status);
    });

final recentOrdersProvider = FutureProvider.autoDispose<List<Order>>((
  ref,
) async {
  final all = await ref.read(orderRepositoryProvider).getMyOrders();
  return all.take(3).toList();
});

/// إحصاءات سريعة للعميل لشاشة "حسابي".
/// لا autoDispose — تُحفظ بين التنقّلات لتجنّب الفلكر. يُستدعى invalidate
/// عند إنشاء/إلغاء طلب جديد.
class CustomerStats {
  final int active; // pending/confirmed/assigned/on_the_way/in_progress
  final int completed;
  final double totalSpent; // مجموع total_amount للمكتملة
  const CustomerStats({
    required this.active,
    required this.completed,
    required this.totalSpent,
  });

  static const empty = CustomerStats(active: 0, completed: 0, totalSpent: 0);
}

final customerStatsProvider = FutureProvider<CustomerStats>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return CustomerStats.empty;

  final rows = await client
      .from('orders')
      .select('status, total_amount')
      .eq('customer_id', userId);

  int active = 0;
  int completed = 0;
  double total = 0;
  const activeStatuses = {
    'pending',
    'confirmed',
    'assigned',
    'on_the_way',
    'in_progress',
  };
  for (final r in rows) {
    final status = r['status'] as String?;
    if (status == null) continue;
    if (activeStatuses.contains(status)) active++;
    if (status == 'completed') {
      completed++;
      total += (r['total_amount'] as num?)?.toDouble() ?? 0;
    }
  }
  return CustomerStats(active: active, completed: completed, totalSpent: total);
});

final activeOrderStreamProvider = StreamProvider.autoDispose<Order?>((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) return Stream.value(null);

  // Listen to the orders table for this user
  return supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('customer_id', userId)
      .map((events) {
        // Find the first order that is NOT completed and NOT cancelled
        final activeEvent = events.firstWhere(
          (e) => e['status'] != 'completed' && e['status'] != 'cancelled',
          orElse: () => <String, dynamic>{}, // Return empty map if none found
        );

        if (activeEvent.isEmpty) return null;
        return Order.fromMap(activeEvent);
      });
});

final orderDetailProvider = FutureProvider.autoDispose.family<Order, String>((
  ref,
  id,
) async {
  return ref.read(orderRepositoryProvider).getOrder(id);
});

final paymentMethodByIdProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, id) async {
      if (id.isEmpty) return null;
      return Supabase.instance.client
          .from('payment_methods')
          .select('id, name, type, account_number')
          .eq('id', id)
          .maybeSingle();
    });

final cartCountProvider = Provider<int>((ref) {
  final cartAsync = ref.watch(cartProvider);
  return cartAsync.maybeWhen(
    data: (cart) => cart.fold(0, (sum, item) => sum + item.quantity),
    orElse: () => 0,
  );
});

final localCartProvider = Provider((ref) => LocalCartRepository());

final cartProvider =
    StateNotifierProvider<CartNotifier, AsyncValue<List<CartItem>>>((ref) {
      return CartNotifier(
        ref.read(cartRepositoryProvider),
        ref.read(localCartProvider),
      );
    });

class CartNotifier extends StateNotifier<AsyncValue<List<CartItem>>> {
  final CartRepository _repository;
  final LocalCartRepository _localRepo;

  CartNotifier(this._repository, this._localRepo)
    : super(const AsyncValue.loading()) {
    loadCart();
  }

  bool get _isGuest => Supabase.instance.client.auth.currentUser == null;

  Future<void> loadCart() async {
    if (_isGuest) {
      state = AsyncValue.data(_localRepo.getCartItems());
      return;
    }
    state = const AsyncValue.loading();
    try {
      final items = await _repository.getCartItems();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addItem(CartItem item) async {
    if (_isGuest) {
      _localRepo.addToCart(item);
      state = AsyncValue.data(_localRepo.getCartItems());
      return;
    }
    try {
      await _repository.addToCart(
        item.product.id,
        item.quantity,
        item.includeInstallation,
      );
      await loadCart();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeItem(String productId) async {
    if (_isGuest) {
      _localRepo.removeItem(productId);
      state = AsyncValue.data(_localRepo.getCartItems());
      return;
    }
    try {
      await _repository.removeItem(productId);
      await loadCart();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateQuantity(String productId, int qty) async {
    if (_isGuest) {
      _localRepo.updateQuantity(productId, qty);
      state = AsyncValue.data(_localRepo.getCartItems());
      return;
    }
    try {
      if (qty <= 0) {
        await removeItem(productId);
        return;
      }
      await _repository.updateQuantity(productId, qty);
      await loadCart();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clear() async {
    if (_isGuest) {
      _localRepo.clear();
      state = const AsyncValue.data([]);
      return;
    }
    try {
      await _repository.clearCart();
      state = const AsyncValue.data([]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// دمج السلة المحلية بعد تسجيل الدخول
  Future<void> mergeGuestCart() async {
    final guestItems = _localRepo.extractAndClear();
    for (final item in guestItems) {
      await _repository.addToCart(
        item.product.id,
        item.quantity,
        item.includeInstallation,
      );
    }
    await loadCart();
  }

  double get total {
    return state.maybeWhen(
      data: (items) => items.fold(0, (sum, i) => sum + i.total),
      orElse: () => 0,
    );
  }
}
