import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/order_repository.dart';
import '../models/order.dart';
import '../models/cart_item.dart';

import '../repositories/cart_repository.dart';

final orderRepositoryProvider = Provider((ref) => OrderRepository());
final cartRepositoryProvider = Provider((ref) => CartRepository());

final myOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  return ref.read(orderRepositoryProvider).getMyOrders();
});

final allOrdersProvider = FutureProvider.autoDispose
    .family<List<Order>, String?>((ref, status) async {
  return ref.read(orderRepositoryProvider).getAllOrders(status: status);
});

final recentOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final all = await ref.read(orderRepositoryProvider).getMyOrders();
  return all.take(3).toList();
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

final orderDetailProvider =
    FutureProvider.autoDispose.family<Order, String>((ref, id) async {
  return ref.read(orderRepositoryProvider).getOrder(id);
});

final cartCountProvider = Provider<int>((ref) {
  final cartAsync = ref.watch(cartProvider);
  return cartAsync.maybeWhen(
    data: (cart) => cart.fold(0, (sum, item) => sum + item.quantity),
    orElse: () => 0,
  );
});

final cartProvider = StateNotifierProvider<CartNotifier, AsyncValue<List<CartItem>>>((ref) {
  return CartNotifier(ref.read(cartRepositoryProvider));
});

class CartNotifier extends StateNotifier<AsyncValue<List<CartItem>>> {
  final CartRepository _repository;

  CartNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCart();
  }

  Future<void> loadCart() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repository.getCartItems();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addItem(CartItem item) async {
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
    try {
      await _repository.removeItem(productId);
      await loadCart();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateQuantity(String productId, int qty) async {
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
    try {
      await _repository.clearCart();
      state = const AsyncValue.data([]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  double get total {
    return state.maybeWhen(
      data: (items) => items.fold(0, (sum, i) => sum + i.total),
      orElse: () => 0,
    );
  }
}
