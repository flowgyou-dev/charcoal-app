import 'package:firebase_database/firebase_database.dart';
import '../models/order_model.dart';
import '../../../core/constants/app_constants.dart';

class OrderService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // 1. Place Order
  Future<CharcoalOrder> placeOrder({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
    required double deliveryLat,
    required double deliveryLng,
    required int sacksOrdered,
    required double pricePerUnit,
  }) async {
    final orderRef = _database.ref(AppConstants.dbOrders).push();
    final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final total = sacksOrdered * pricePerUnit;
    final order = CharcoalOrder(
      id: orderId,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      deliveryAddress: deliveryAddress,
      deliveryLat: deliveryLat,
      deliveryLng: deliveryLng,
      sacksOrdered: sacksOrdered,
      pricePerUnit: pricePerUnit,
      totalAmount: total,
      paymentMethod: 'COD',
      status: 'Pending',
      createdAt: DateTime.now().toIso8601String(),
    );

    await orderRef.set(order.toMap());
    return order;
  }

  // 2. Stream Customer Orders
  Stream<List<CharcoalOrder>> streamCustomerOrders(String customerId) {
    return _database.ref(AppConstants.dbOrders).onValue.map((event) {
      if (!event.snapshot.exists) return [];
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final list = <CharcoalOrder>[];

      for (final entry in data.entries) {
        final orderMap = entry.value as Map<dynamic, dynamic>;
        if (orderMap['customerId']?.toString() == customerId) {
          list.add(CharcoalOrder.fromMap(entry.key.toString(), orderMap));
        }
      }

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // 3. Stream Live Driver Location for Order
  Stream<Map<String, double>?> streamDriverLocation(String driverId) {
    return _database.ref('${AppConstants.dbDriverLocations}/$driverId').onValue.map((event) {
      if (!event.snapshot.exists) return null;
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final lat = double.tryParse(data['latitude']?.toString() ?? '');
      final lng = double.tryParse(data['longitude']?.toString() ?? '');
      if (lat != null && lng != null) {
        return {'lat': lat, 'lng': lng};
      }
      return null;
    });
  }
}
