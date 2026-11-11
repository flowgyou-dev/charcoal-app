class AppUser {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final String role; // 'customer' | 'driver'
  final bool isActive;
  final String? createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.isActive = true,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  factory AppUser.fromMap(String uid, Map<dynamic, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      role: map['role']?.toString() ?? 'customer',
      isActive: map['isActive'] != false,
      createdAt: map['createdAt']?.toString(),
    );
  }
}
