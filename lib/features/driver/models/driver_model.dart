class DriverProfile {
  final String driverId;
  final String name;
  final String phone;
  final String vehicle;
  final String plateNumber;
  final String email;

  DriverProfile({
    required this.driverId,
    required this.name,
    required this.phone,
    required this.vehicle,
    required this.plateNumber,
    required this.email,
  });

  factory DriverProfile.fromMap(String id, Map<dynamic, dynamic> map) {
    return DriverProfile(
      driverId: id,
      name: map['name']?.toString() ?? 'Driver',
      phone: map['phone']?.toString() ?? '',
      vehicle: map['vehicle']?.toString() ?? 'Motorcycle',
      plateNumber: map['plateNumber']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
    );
  }
}
