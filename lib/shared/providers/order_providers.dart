import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/order_repository.dart';
import '../models/order.dart';
import '../models/cart_item.dart';

final orderRepositoryProvider = Provider((ref) => OrderRepository());

final myOrdersProvider = FutureProvider<List<Order>>((ref) async {
  return ref.read(orderRepositoryProvider).getMyOrders();
});

final allOrdersProvider = FutureProvider.family<List<Order>, String?>((
  ref,
  status,
) async {
  return ref.read(orderRepositoryProvider).getAllOrders(status: status);
});

final orderDetailProvider = FutureProvider.family<Order, String>((
  ref,
  id,
) async {
  return ref.read(orderRepositoryProvider).getOrder(id);
});

// سلة المشتريات (في الذاكرة)
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>(
  (ref) => CartNotifier(),
);

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(CartItem item) {
    final idx = state.indexWhere((i) => i.product.id == item.product.id);
    if (idx >= 0) {
      state[idx].quantity += item.quantity;
      state = [...state];
    } else {
      state = [...state, item];
    }
  }

  void removeItem(String productId) {
    state = state.where((i) => i.product.id != productId).toList();
  }

  void updateQuantity(String productId, int qty) {
    final idx = state.indexWhere((i) => i.product.id == productId);
    if (idx >= 0) {
      if (qty <= 0) {
        removeItem(productId);
        return;
      }
      state[idx].quantity = qty;
      state = [...state];
    }
  }

  void clear() => state = [];

  double get total => state.fold(0, (sum, i) => sum + i.total);
}
