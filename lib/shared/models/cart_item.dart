import 'product.dart';

class CartItem {
  final Product product;
  int quantity;
  bool includeInstallation;

  CartItem({
    required this.product, 
    this.quantity = 1,
    this.includeInstallation = false,
  });

  double get total => ((product.price ?? 0) + (includeInstallation ? product.installationPrice : 0)) * quantity;
}
