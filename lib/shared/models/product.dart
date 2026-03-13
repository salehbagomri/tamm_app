class Product {
  final String id;
  final String name;
  final String? description;
  final String category;
  final double? price;
  final bool isPriceOnRequest;
  final String? imageUrl;
  final String? brand;
  final Map<String, dynamic> specs;
  final bool isAvailable;
  final bool isFeatured;
  final bool requiresInstallation;

  const Product({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.price,
    this.isPriceOnRequest = false,
    this.imageUrl,
    this.brand,
    this.specs = const {},
    this.isAvailable = true,
    this.isFeatured = false,
    this.requiresInstallation = false,
  });

  factory Product.fromMap(Map<String, dynamic> m) => Product(
    id: m['id'],
    name: m['name'],
    description: m['description'],
    category: m['category'],
    price: (m['price'] as num?)?.toDouble(),
    isPriceOnRequest: m['is_price_on_request'] ?? false,
    imageUrl: m['image_url'],
    brand: m['brand'],
    specs: m['specs'] ?? {},
    isAvailable: m['is_available'] ?? true,
    isFeatured: m['is_featured'] ?? false,
    requiresInstallation: m['requires_installation'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'category': category,
    'price': price,
    'is_price_on_request': isPriceOnRequest,
    'image_url': imageUrl,
    'brand': brand,
    'specs': specs,
    'is_available': isAvailable,
    'is_featured': isFeatured,
    'requires_installation': requiresInstallation,
  };

  String get categoryLabel => switch (category) {
    'ac' => 'مكيفات',
    'solar_panel' => 'ألواح شمسية',
    'solar_battery' => 'بطاريات',
    'solar_inverter' => 'إنفرتر',
    'accessory' => 'إكسسوارات',
    _ => category,
  };
}
