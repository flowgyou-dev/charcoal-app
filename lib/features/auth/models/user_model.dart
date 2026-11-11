class AppUser {
  final String uid;
  final String email;
  final String name;
  final String firstName;
  final String middleName;
  final String lastName;
  final String phone;
  final String role; // 'customer' | 'driver'
  final bool isActive;
  final bool emailVerified;
  final String? createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    required this.phone,
    required this.role,
    this.isActive = true,
    this.emailVerified = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      if (firstName.isNotEmpty) 'firstName': firstName,
      if (middleName.isNotEmpty) 'middleName': middleName,
      if (lastName.isNotEmpty) 'lastName': lastName,
      'phone': phone,
      'role': role,
      'isActive': isActive,
      'emailVerified': emailVerified,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  factory AppUser.fromMap(String uid, Map<dynamic, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      firstName: map['firstName']?.toString() ?? '',
      middleName: map['middleName']?.toString() ?? '',
      lastName: map['lastName']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      role: map['role']?.toString() ?? 'customer',
      isActive: map['isActive'] != false,
      emailVerified: map['emailVerified'] == true,
      createdAt: map['createdAt']?.toString(),
    );
  }
}
