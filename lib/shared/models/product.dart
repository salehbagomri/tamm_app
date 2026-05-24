class Product {
  final String id;
  final String name;
  final String? description;
  final String category;
  final double? price;
  final bool isPriceOnRequest;
  final String? imageUrl;
  final List<String> imageUrls;
  final String? brand;
  final Map<String, dynamic> specs;
  final bool isAvailable;
  final bool isFeatured;
  final bool requiresInstallation;
  final double installationPrice;
  final double? oldPrice;

  // ─── حقول المخزون (Phase 1) ───
  final int stockQuantity;
  final int lowStockThreshold;
  final bool autoHideWhenOut;
  final double? costPrice;
  final String? supplierName;
  final String? supplierSku;

  const Product({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.price,
    this.isPriceOnRequest = false,
    this.imageUrl,
    this.imageUrls = const [],
    this.brand,
    this.specs = const {},
    this.isAvailable = true,
    this.isFeatured = false,
    this.requiresInstallation = false,
    this.installationPrice = 0.0,
    this.oldPrice,
    this.stockQuantity = 0,
    this.lowStockThreshold = 3,
    this.autoHideWhenOut = true,
    this.costPrice,
    this.supplierName,
    this.supplierSku,
  });

  factory Product.fromMap(Map<String, dynamic> m) => Product(
    id: m['id'],
    name: m['name'],
    description: m['description'],
    category: m['category'],
    price: (m['price'] as num?)?.toDouble(),
    isPriceOnRequest: m['is_price_on_request'] ?? false,
    imageUrl: m['image_url'],
    imageUrls: m['image_urls'] != null
        ? List<String>.from(m['image_urls'])
        : [],
    brand: m['brand'],
    specs: m['specs'] ?? {},
    isAvailable: m['is_available'] ?? true,
    isFeatured: m['is_featured'] ?? false,
    requiresInstallation: m['requires_installation'] ?? false,
    installationPrice: (m['installation_price'] as num?)?.toDouble() ?? 0.0,
    oldPrice: (m['old_price'] as num?)?.toDouble(),
    stockQuantity: (m['stock_quantity'] as num?)?.toInt() ?? 0,
    lowStockThreshold: (m['low_stock_threshold'] as num?)?.toInt() ?? 3,
    autoHideWhenOut: m['auto_hide_when_out'] ?? true,
    costPrice: (m['cost_price'] as num?)?.toDouble(),
    supplierName: m['supplier_name'],
    supplierSku: m['supplier_sku'],
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'category': category,
    'price': price,
    'is_price_on_request': isPriceOnRequest,
    'image_url': imageUrl,
    'image_urls': imageUrls,
    'brand': brand,
    'specs': specs,
    'is_available': isAvailable,
    'is_featured': isFeatured,
    'requires_installation': requiresInstallation,
    'installation_price': installationPrice,
    'old_price': oldPrice,
    'stock_quantity': stockQuantity,
    'low_stock_threshold': lowStockThreshold,
    'auto_hide_when_out': autoHideWhenOut,
    'cost_price': costPrice,
    'supplier_name': supplierName,
    'supplier_sku': supplierSku,
  };

  List<String> get allImageUrls {
    if (imageUrls.isNotEmpty) return imageUrls;
    if (imageUrl != null && imageUrl!.isNotEmpty) return [imageUrl!];
    return [];
  }

  bool get hasDiscount =>
      oldPrice != null && price != null && oldPrice! > price!;
  int get discountPercentage =>
      hasDiscount ? (((oldPrice! - price!) / oldPrice!) * 100).round() : 0;

  // ─── Stock helpers ───
  bool get isInStock => stockQuantity > 0;
  bool get isOutOfStock => !isAvailable || stockQuantity <= 0;
  bool get isLowStock => isInStock && stockQuantity <= lowStockThreshold;

  String get categoryLabel => switch (category) {
    'ac' => 'مكيفات',
    'solar_panel' => 'ألواح شمسية',
    'solar_battery' => 'بطاريات',
    'solar_inverter' => 'إنفرتر',
    'accessory' => 'إكسسوارات',
    _ => category,
  };
}
