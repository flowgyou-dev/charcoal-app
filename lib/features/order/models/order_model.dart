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
  final double subtotalAmount;
  final double deliveryFee;
  final double totalAmount;
  final String paymentMethod; // 'COD' | 'ONLINE_QR'
  final String paymentStatus; // 'Unpaid' | 'Pending Verification' | 'Verified' | 'Paid'
  final String? receiptRefNumber;
  final double? ocrDetectedAmount;
  final bool hasReceipt;
  final String status; // 'Pending' | 'Confirmed' | 'Out for Delivery' | 'Delivered' | 'Cancelled'
  final String? cancelReason;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String createdAt;
  final String? outForDeliveryAt;
  final String? deliveredAt;

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
    double? subtotalAmount,
    this.deliveryFee = 0,
    required this.totalAmount,
    required this.paymentMethod,
    this.paymentStatus = 'Unpaid',
    this.receiptRefNumber,
    this.ocrDetectedAmount,
    this.hasReceipt = false,
    required this.status,
    this.cancelReason,
    this.driverId,
    this.driverName,
    this.driverPhone,
    required this.createdAt,
    this.outForDeliveryAt,
    this.deliveredAt,
  }) : subtotalAmount = subtotalAmount ?? (sacksOrdered * pricePerUnit);

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
      'subtotalAmount': subtotalAmount,
      'deliveryFee': deliveryFee,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      if (receiptRefNumber != null) 'receiptRefNumber': receiptRefNumber,
      if (ocrDetectedAmount != null) 'ocrDetectedAmount': ocrDetectedAmount,
      'hasReceipt': hasReceipt,
      'status': status,
      if (cancelReason != null) 'cancelReason': cancelReason,
      'driverId': driverId,
      'driverName': driverName,
      if (driverPhone != null) 'driverPhone': driverPhone,
      'createdAt': createdAt,
      if (outForDeliveryAt != null) 'outForDeliveryAt': outForDeliveryAt,
      if (deliveredAt != null) 'deliveredAt': deliveredAt,
    };
  }

  factory CharcoalOrder.fromMap(String id, Map<dynamic, dynamic> map) {
    final sacks = int.tryParse(map['sacksOrdered']?.toString() ?? '1') ?? 1;
    final unitPrice = double.tryParse(map['pricePerUnit']?.toString() ?? '250.0') ?? 250.0;
    final sub = double.tryParse(map['subtotalAmount']?.toString() ?? '') ?? (sacks * unitPrice);
    final fee = double.tryParse(map['deliveryFee']?.toString() ?? '0') ?? 0.0;

    return CharcoalOrder(
      id: id,
      customerId: map['customerId']?.toString() ?? '',
      customerName: map['customerName']?.toString() ?? 'Customer',
      customerPhone: map['customerPhone']?.toString() ?? '',
      deliveryAddress: map['deliveryAddress']?.toString() ?? '',
      deliveryLat: double.tryParse(map['deliveryLat']?.toString() ?? '14.6042') ?? 14.6042,
      deliveryLng: double.tryParse(map['deliveryLng']?.toString() ?? '120.9822') ?? 120.9822,
      sacksOrdered: sacks,
      pricePerUnit: unitPrice,
      subtotalAmount: sub,
      deliveryFee: fee,
      totalAmount: double.tryParse(map['totalAmount']?.toString() ?? '') ?? (sub + fee),
      paymentMethod: map['paymentMethod']?.toString() ?? 'COD',
      paymentStatus: map['paymentStatus']?.toString() ?? 'Unpaid',
      receiptRefNumber: map['receiptRefNumber']?.toString(),
      ocrDetectedAmount: double.tryParse(map['ocrDetectedAmount']?.toString() ?? ''),
      hasReceipt: map['hasReceipt'] == true,
      status: map['status']?.toString() ?? 'Pending',
      cancelReason: map['cancelReason']?.toString(),
      driverId: map['driverId']?.toString(),
      driverName: map['driverName']?.toString(),
      driverPhone: map['driverPhone']?.toString(),
      createdAt: map['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      outForDeliveryAt: map['outForDeliveryAt']?.toString(),
      deliveredAt: map['deliveredAt']?.toString(),
    );
  }
}
