class CharcoalOrder {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final double deliveryLat;
  final double deliveryLng;
  final int sacksOrdered;
  final double pricePerUnit;
  final double totalAmount;
  final String paymentMethod;
  final String status; // 'Pending' | 'Confirmed' | 'Out for Delivery' | 'Delivered' | 'Cancelled'
  final String? driverId;
  final String? driverName;
  final String createdAt;

  CharcoalOrder({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.deliveryLat,
    required this.deliveryLng,
    required this.sacksOrdered,
    required this.pricePerUnit,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    this.driverId,
    this.driverName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'deliveryLat': deliveryLat,
      'deliveryLng': deliveryLng,
      'sacksOrdered': sacksOrdered,
      'pricePerUnit': pricePerUnit,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'status': status,
      'driverId': driverId,
      'driverName': driverName,
      'createdAt': createdAt,
    };
  }

  factory CharcoalOrder.fromMap(String id, Map<dynamic, dynamic> map) {
    return CharcoalOrder(
      id: id,
      customerId: map['customerId']?.toString() ?? '',
      customerName: map['customerName']?.toString() ?? 'Customer',
      customerPhone: map['customerPhone']?.toString() ?? '',
      deliveryAddress: map['deliveryAddress']?.toString() ?? '',
      deliveryLat: double.tryParse(map['deliveryLat']?.toString() ?? '14.6042') ?? 14.6042,
      deliveryLng: double.tryParse(map['deliveryLng']?.toString() ?? '120.9822') ?? 120.9822,
      sacksOrdered: int.tryParse(map['sacksOrdered']?.toString() ?? '1') ?? 1,
      pricePerUnit: double.tryParse(map['pricePerUnit']?.toString() ?? '250.0') ?? 250.0,
      totalAmount: double.tryParse(map['totalAmount']?.toString() ?? '250.0') ?? 250.0,
      paymentMethod: map['paymentMethod']?.toString() ?? 'COD',
      status: map['status']?.toString() ?? 'Pending',
      driverId: map['driverId']?.toString(),
      driverName: map['driverName']?.toString(),
      createdAt: map['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }
}
