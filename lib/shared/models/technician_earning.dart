class TechnicianEarning {
  final String id;
  final String technicianId;
  final String orderId;
  final String taskType;
  final double orderAmount;
  final double commissionAmount;
  final bool isPaid;
  final DateTime? paidAt;
  final String? notes;
  final DateTime createdAt;
  final String? orderNumber;

  const TechnicianEarning({
    required this.id,
    required this.technicianId,
    required this.orderId,
    required this.taskType,
    required this.orderAmount,
    required this.commissionAmount,
    required this.isPaid,
    this.paidAt,
    this.notes,
    required this.createdAt,
    this.orderNumber,
  });

  factory TechnicianEarning.fromMap(Map<String, dynamic> m) {
    final order = m['orders'] as Map<String, dynamic>?;
    return TechnicianEarning(
      id: m['id'] as String,
      technicianId: m['technician_id'] as String,
      orderId: m['order_id'] as String,
      taskType: m['task_type'] as String,
      orderAmount: (m['order_amount'] as num?)?.toDouble() ?? 0,
      commissionAmount: (m['commission_amount'] as num?)?.toDouble() ?? 0,
      isPaid: (m['is_paid'] as bool?) ?? false,
      paidAt: m['paid_at'] != null
          ? DateTime.parse(m['paid_at'] as String)
          : null,
      notes: m['notes'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
      orderNumber: order?['order_number'] as String?,
    );
  }

  String get taskTypeLabel {
    switch (taskType) {
      case 'installation':
        return 'تركيب';
      case 'maintenance':
        return 'صيانة';
      case 'inspection':
        return 'كشف ومعاينة';
      case 'quote_visit':
        return 'زيارة عرض سعر';
      default:
        return taskType;
    }
  }
}
