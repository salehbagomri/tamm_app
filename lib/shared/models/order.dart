
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
  final String? technicianId;

  // New Fields
  final String? scheduledPeriod;
  final String? scheduledHour;
  final double? quotePrice;
  final String? quoteDetails;
  final String? quoteDuration;
  final String? quoteStatus;
  final DateTime? quoteSentAt;
  final DateTime? quoteRespondedAt;
  final String? rejectionReason;
  final String? quoteAttachmentUrl;
  final String paymentType;
  final String? paymentMethodId;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? receiptUrl;
  final String? contactPhone;

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
    this.technicianId,
    this.scheduledPeriod,
    this.scheduledHour,
    this.quotePrice,
    this.quoteDetails,
    this.quoteDuration,
    this.quoteStatus,
    this.quoteSentAt,
    this.quoteRespondedAt,
    this.rejectionReason,
    this.quoteAttachmentUrl,
    this.paymentType = 'cash',
    this.paymentMethodId,
    this.city,
    this.latitude,
    this.longitude,
    this.receiptUrl,
    this.contactPhone,
  });

  factory Order.fromMap(Map<String, dynamic> m) {
    String? tNotes;
    String? tName;
    String? tId;
    final assignments = m['assignments'] as List?;
    if (assignments != null && assignments.isNotEmpty) {
      final a = assignments.first as Map<String, dynamic>;
      tNotes = a['technician_notes']?.toString();
      tId = a['technician_id'] as String?;
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
      technicianId: tId,
      scheduledPeriod: m['scheduled_period'],
      scheduledHour: m['scheduled_hour'],
      quotePrice: (m['quote_price'] as num?)?.toDouble(),
      quoteDetails: m['quote_details'],
      quoteDuration: m['quote_duration'],
      quoteStatus: m['quote_status'],
      quoteSentAt: m['quote_sent_at'] != null
          ? DateTime.parse(m['quote_sent_at'])
          : null,
      quoteRespondedAt: m['quote_responded_at'] != null
          ? DateTime.parse(m['quote_responded_at'])
          : null,
      rejectionReason: m['rejection_reason'],
      quoteAttachmentUrl: m['quote_attachment_url'],
      paymentType: m['payment_type'] as String? ?? 'cash',
      paymentMethodId: m['payment_method_id'] as String?,
      city: m['city'] as String?,
      latitude: (m['latitude'] as num?)?.toDouble(),
      longitude: (m['longitude'] as num?)?.toDouble(),
      receiptUrl: m['receipt_url'] as String?,
      contactPhone: m['contact_phone'] as String?,
    );
  }

  String get statusLabel {
    if (orderType == 'quote_request') {
      if ([
        'confirmed',
        'assigned',
        'on_the_way',
        'in_progress',
        'completed',
        'cancelled',
      ].contains(status)) {
        return switch (status) {
          'confirmed' => 'مؤكد - بانتظار التعيين',
          'assigned' => 'تم التعيين',
          'on_the_way' => 'الفني في الطريق',
          'in_progress' => 'جاري التنفيذ',
          'completed' => 'مكتمل',
          'cancelled' => 'ملغي',
          _ => status,
        };
      }
      // مرحلة العرض
      if (quoteStatus == 'pending') return 'بانتظار العرض';
      if (quoteStatus == 'sent') return 'تم إرسال العرض';
      if (quoteStatus == 'accepted') return 'تم قبول العرض';
      if (quoteStatus == 'rejected') return 'عرض مرفوض';
    }

    return switch (status) {
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

  String get orderTypeLabel => switch (orderType) {
    'product' => 'طلب منتج',
    'service' => 'طلب خدمة',
    'product_and_service' => 'منتج وخدمة',
    'quote_request' => 'طلب عرض سعر',
    _ => 'طلب',
  };

  String get quoteStatusLabel => switch (quoteStatus) {
    'pending' => 'بانتظار العرض',
    'sent' => 'تم إرسال العرض',
    'accepted' => 'تم قبول العرض',
    'rejected' => 'مرفوض - بانتظار عرض جديد',
    _ => 'غير محدد',
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
  final bool includeInstallation;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.itemType,
    this.productId,
    this.serviceTypeId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.includeInstallation = false,
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
    includeInstallation: m['include_installation'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'order_id': orderId,
    'item_type': itemType,
    'product_id': productId,
    'service_type_id': serviceTypeId,
    'quantity': quantity,
    'unit_price': unitPrice,
    'total_price': totalPrice,
    'include_installation': includeInstallation,
  };

  OrderItem copyWith({
    String? id,
    String? orderId,
    String? itemType,
    String? productId,
    String? serviceTypeId,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    bool? includeInstallation,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      itemType: itemType ?? this.itemType,
      productId: productId ?? this.productId,
      serviceTypeId: serviceTypeId ?? this.serviceTypeId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      includeInstallation: includeInstallation ?? this.includeInstallation,
    );
  }
}
