class Review {
  final String id;
  final String orderId;
  final String customerId;
  final String? technicianId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.orderId,
    required this.customerId,
    this.technicianId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> m) => Review(
    id: m['id'] as String,
    orderId: m['order_id'] as String,
    customerId: m['customer_id'] as String,
    technicianId: m['technician_id'] as String?,
    rating: (m['rating'] as num).toInt(),
    comment: m['comment'] as String?,
    createdAt: DateTime.parse(m['created_at'] as String),
  );
}
