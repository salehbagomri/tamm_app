class Order {
  final String id;
  final String orderNumber;
  final String customerId;
  final String orderType;
  final String status;
  final double totalAmount;
  final String address;
  final DateTime? preferredDate;
  final String? preferredTimeSlot;
  final String? notes;
  final bool includeInstallation;
  final DateTime createdAt;
  final List<OrderItem> items;
  final Map<String, dynamic>? customerProfile;
  final String? technicianNotes;
  final String? technicianName;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.orderType,
    required this.status,
    required this.totalAmount,
    required this.address,
    this.preferredDate,
    this.preferredTimeSlot,
    this.notes,
    this.includeInstallation = false,
    required this.createdAt,
    this.items = const [],
    this.customerProfile,
    this.technicianNotes,
    this.technicianName,
  });

  factory Order.fromMap(Map<String, dynamic> m) {
    String? tNotes;
    String? tName;
    final assignments = m['assignments'] as List?;
    if (assignments != null && assignments.isNotEmpty) {
      final a = assignments.first as Map<String, dynamic>;
      tNotes = a['technician_notes']?.toString();
      final t = a['technicians'] as Map<String, dynamic>?;
      if (t != null) {
        final p = t['profiles'] as Map<String, dynamic>?;
        tName = p?['full_name']?.toString();
      }
    }

    return Order(
      id: m['id'],
      orderNumber: m['order_number'],
      customerId: m['customer_id'],
      orderType: m['order_type'],
      status: m['status'],
      totalAmount: (m['total_amount'] as num?)?.toDouble() ?? 0,
      address: m['address'] ?? '',
      preferredDate: m['preferred_date'] != null
          ? DateTime.tryParse(m['preferred_date'])
          : null,
      preferredTimeSlot: m['preferred_time_slot'],
      notes: m['notes'],
      includeInstallation: m['include_installation'] ?? false,
      createdAt: DateTime.parse(m['created_at']),
      items:
          (m['order_items'] as List?)
              ?.map((e) => OrderItem.fromMap(e))
              .toList() ??
          [],
      customerProfile: m['profiles'] as Map<String, dynamic>?,
      technicianNotes: tNotes,
      technicianName: tName,
    );
  }

  String get statusLabel => switch (status) {
    'pending' => 'معلق',
    'confirmed' => 'مؤكد',
    'assigned' => 'تم التعيين',
    'on_the_way' => 'في الطريق',
    'in_progress' => 'جاري التنفيذ',
    'completed' => 'مكتمل',
    'cancelled' => 'ملغي',
    _ => status,
  };
}

class OrderItem {
  final String id;
  final String orderId;
  final String itemType;
  final String? productId;
  final String? serviceTypeId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.itemType,
    this.productId,
    this.serviceTypeId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
    id: m['id'],
    orderId: m['order_id'],
    itemType: m['item_type'],
    productId: m['product_id'],
    serviceTypeId: m['service_type_id'],
    quantity: m['quantity'] ?? 1,
    unitPrice: (m['unit_price'] as num).toDouble(),
    totalPrice: (m['total_price'] as num).toDouble(),
  );
}
