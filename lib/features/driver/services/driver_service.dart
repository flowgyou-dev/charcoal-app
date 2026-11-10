import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import '../../order/models/order_model.dart';
import '../../../core/constants/app_constants.dart';

class DriverService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  StreamSubscription<Position>? _positionSubscription;

  // 1. Start Broadcasting GPS Stream to Realtime Database
  Future<void> startGpsBroadcast(String driverId, String driverName) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
      return;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // update every 5 meters
    );

    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      _database.ref('${AppConstants.dbDriverLocations}/$driverId').set({
        'driverId': driverId,
        'driverName': driverName,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'heading': position.heading,
        'speed': position.speed,
        'isOnline': true,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    });

    // Mark driver as online in drivers list
    await _database.ref('${AppConstants.dbDrivers}/$driverId').update({'isOnline': true});
  }

  // 2. Stop GPS Broadcast
  Future<void> stopGpsBroadcast(String driverId) async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await _database.ref('${AppConstants.dbDriverLocations}/$driverId').update({'isOnline': false});
    await _database.ref('${AppConstants.dbDrivers}/$driverId').update({'isOnline': false});
  }

  // 3. Stream Assigned Orders for this Driver
  Stream<List<CharcoalOrder>> streamAssignedOrders(String driverId) {
    return _database.ref(AppConstants.dbOrders).onValue.map((event) {
      if (!event.snapshot.exists) return [];
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final list = <CharcoalOrder>[];

      for (final entry in data.entries) {
        final orderMap = entry.value as Map<dynamic, dynamic>;
        if (orderMap['driverId']?.toString() == driverId) {
          list.add(CharcoalOrder.fromMap(entry.key.toString(), orderMap));
        }
      }

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // 4. Mark Order Delivered and Auto-Deduct Inventory
  Future<void> completeOrder(CharcoalOrder order) async {
    // A. Update order status
    await _database.ref('${AppConstants.dbOrders}/${order.id}').update({
      'status': 'Delivered',
      'deliveredAt': DateTime.now().toIso8601String(),
    });

    // B. Deduct stock from inventory
    final invSnap = await _database.ref(AppConstants.dbInventory).get();
    if (invSnap.exists) {
      final invData = invSnap.value as Map<dynamic, dynamic>;
      final currentStock = int.tryParse(invData['currentStock']?.toString() ?? '0') ?? 0;
      final newStock = (currentStock - order.sacksOrdered).clamp(0, 999999);

      await _database.ref(AppConstants.dbInventory).update({
        'currentStock': newStock,
        'lastUpdated': DateTime.now().toIso8601String(),
      });

      // C. Log to inventory_history
      await _database.ref('inventory_history').push().set({
        'type': 'DEDUCTION',
        'quantity': order.sacksOrdered,
        'reason': 'Delivered to ${order.customerName} (${order.id})',
        'newBalance': newStock,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }
}
