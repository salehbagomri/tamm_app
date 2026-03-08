class ServiceType {
  final String id;
  final String name;
  final String? description;
  final String category;
  final double? basePrice;
  final String? iconName;
  final bool isActive;

  const ServiceType({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.basePrice,
    this.iconName,
    this.isActive = true,
  });

  factory ServiceType.fromMap(Map<String, dynamic> m) => ServiceType(
    id: m['id'],
    name: m['name'],
    description: m['description'],
    category: m['category'],
    basePrice: (m['base_price'] as num?)?.toDouble(),
    iconName: m['icon_name'],
    isActive: m['is_active'] ?? true,
  );
}
