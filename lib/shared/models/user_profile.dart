class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String role; // customer, manager, technician
  final bool isComplete;
  final String? avatarUrl;
  final String? address;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    this.isComplete = false,
    this.avatarUrl,
    this.address,
    required this.createdAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: map['role'] as String? ?? 'customer',
      isComplete: map['is_complete'] as bool? ?? false,
      avatarUrl: map['avatar_url'] as String?,
      address: map['address'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'is_complete': isComplete,
      'avatar_url': avatarUrl,
      'address': address,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? role,
    bool? isComplete,
    String? avatarUrl,
    String? address,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isComplete: isComplete ?? this.isComplete,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isCustomer => role == 'customer';
  bool get isManager => role == 'manager';
  bool get isTechnician => role == 'technician';
}
