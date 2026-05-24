class SavedAddress {
  final String id;
  final String userId;
  final String label;
  final String address;
  final String city;
  final double? lat;
  final double? lng;
  final bool isDefault;
  final DateTime createdAt;

  const SavedAddress({
    required this.id,
    required this.userId,
    required this.label,
    required this.address,
    required this.city,
    this.lat,
    this.lng,
    required this.isDefault,
    required this.createdAt,
  });

  factory SavedAddress.fromMap(Map<String, dynamic> m) => SavedAddress(
    id: m['id'] as String,
    userId: m['user_id'] as String,
    label: m['label'] as String? ?? 'المنزل',
    address: m['address'] as String,
    city: m['city'] as String? ?? 'المكلا',
    lat: (m['lat'] as num?)?.toDouble(),
    lng: (m['lng'] as num?)?.toDouble(),
    isDefault: m['is_default'] as bool? ?? false,
    createdAt: DateTime.parse(m['created_at'] as String),
  );

  Map<String, dynamic> toInsertMap() => {
    'user_id': userId,
    'label': label,
    'address': address,
    'city': city,
    if (lat != null) 'lat': lat,
    if (lng != null) 'lng': lng,
    'is_default': isDefault,
  };

  SavedAddress copyWith({
    String? label,
    String? address,
    String? city,
    double? lat,
    double? lng,
    bool? isDefault,
  }) => SavedAddress(
    id: id,
    userId: userId,
    label: label ?? this.label,
    address: address ?? this.address,
    city: city ?? this.city,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    isDefault: isDefault ?? this.isDefault,
    createdAt: createdAt,
  );
}
