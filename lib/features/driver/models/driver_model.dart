class DriverProfile {
  final String driverId;
  final String name;
  final String phone;
  final String vehicle;
  final String plateNumber;
  final String email;
  final bool isOnline;
  final bool isActive;

  DriverProfile({
    required this.driverId,
    required this.name,
    required this.phone,
    required this.vehicle,
    required this.plateNumber,
    required this.email,
    this.isOnline = false,
    this.isActive = true,
  });

  factory DriverProfile.fromMap(String id, Map<dynamic, dynamic> map) {
    return DriverProfile(
      driverId: id,
      name: map['name']?.toString() ?? 'Driver',
      phone: map['phone']?.toString() ?? '',
      vehicle: map['vehicle']?.toString() ?? 'Motorcycle',
      plateNumber: map['plateNumber']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      isOnline: map['isOnline'] == true,
      isActive: map['isActive'] != false,
    );
  }
}
