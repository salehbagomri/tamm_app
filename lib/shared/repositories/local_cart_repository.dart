import '../models/cart_item.dart';

/// سلة محلية للزوار — تُحفظ في الذاكرة فقط
class LocalCartRepository {
  final List<CartItem> _items = [];

  List<CartItem> getCartItems() => List.unmodifiable(_items);

  void addToCart(CartItem item) {
    final idx = _items.indexWhere((e) => e.product.id == item.product.id);
    if (idx >= 0) {
      _items[idx].quantity += item.quantity;
      _items[idx].includeInstallation = item.includeInstallation;
    } else {
      _items.add(item);
    }
  }

  void updateQuantity(String productId, int qty) {
    if (qty <= 0) { removeItem(productId); return; }
    final idx = _items.indexWhere((e) => e.product.id == productId);
    if (idx >= 0) _items[idx].quantity = qty;
  }

  void removeItem(String productId) {
    _items.removeWhere((e) => e.product.id == productId);
  }

  void clear() => _items.clear();

  /// يُستدعى بعد تسجيل الدخول لدمج السلة مع Supabase
  List<CartItem> extractAndClear() {
    final copy = List<CartItem>.from(_items);
    _items.clear();
    return copy;
  }
}
