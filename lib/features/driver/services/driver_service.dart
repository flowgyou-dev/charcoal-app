import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import '../../order/models/order_model.dart';
import '../../../core/constants/app_constants.dart';

class DriverService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  StreamSubscription<Position>? _positionSubscription;

  // 1. Start Broadcasting GPS Stream to Realtime Database + configure onDisconnect
  Future<bool> startGpsBroadcast(String driverId, String driverName) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
      return false;
    }

    final locRef = _database.ref('${AppConstants.dbDriverLocations}/$driverId');
    final driverRef = _database.ref('${AppConstants.dbDrivers}/$driverId');

    // Automatically mark offline if connection drops or app is force-killed
    try {
      await driverRef.child('isOnline').onDisconnect().set(false);
    } catch (_) {}

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    bool locDisconnectRegistered = false;
    Future<void> registerLocDisconnectOnce() async {
      if (locDisconnectRegistered) return;
      try {
        await locRef.child('isOnline').onDisconnect().set(false);
        locDisconnectRegistered = true;
      } catch (_) {}
    }

    // Send immediate initial position
    try {
      final initial = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await locRef.set({
        'driverId': driverId,
        'driverName': driverName,
        'latitude': initial.latitude,
        'longitude': initial.longitude,
        'heading': initial.heading,
        'speed': initial.speed,
        'isOnline': true,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
      await registerLocDisconnectOnce();
    } catch (_) {
      // Wait for stream position if single shot fails
    }

    await _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) async {
        try {
          await locRef.set({
            'driverId': driverId,
            'driverName': driverName,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'heading': position.heading,
            'speed': position.speed,
            'isOnline': true,
            'lastUpdated': DateTime.now().toIso8601String(),
          });
          await registerLocDisconnectOnce();
        } catch (_) {}
      },
      onError: (_) {},
    );

    await driverRef.update({'isOnline': true});
    return true;
  }

  // 2. Stop GPS Broadcast
  Future<void> stopGpsBroadcast(String driverId) async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    try {
      final locRef = _database.ref('${AppConstants.dbDriverLocations}/$driverId');
      final snap = await locRef.get();
      if (snap.exists) {
        await locRef.update({'isOnline': false});
      }
    } catch (_) {}
    try {
      await _database.ref('${AppConstants.dbDrivers}/$driverId').update({'isOnline': false});
    } catch (_) {}
  }

  // 3. Stream Assigned Orders for this Driver
  Stream<List<CharcoalOrder>> streamAssignedOrders(String driverId) {
    return _database
        .ref(AppConstants.dbOrders)
        .orderByChild('driverId')
        .equalTo(driverId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists || event.snapshot.value is! Map) return [];
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final list = <CharcoalOrder>[];

      for (final entry in data.entries) {
        if (entry.value is Map) {
          list.add(CharcoalOrder.fromMap(entry.key.toString(), entry.value as Map<dynamic, dynamic>));
        }
      }

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // 4. Transition Confirmed -> Out for Delivery
  Future<void> startDelivery(CharcoalOrder order) async {
    if (order.status != 'Confirmed') return;
    await _database.ref('${AppConstants.dbOrders}/${order.id}').update({
      'status': 'Out for Delivery',
      'outForDeliveryAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // 5. Mark Order Delivered & Paid (stock was already atomically reserved upon checkout)
  Future<void> completeOrder(CharcoalOrder order) async {
    if (order.status == 'Delivered' || order.status == 'Cancelled') {
      return;
    }

    final statusSnap = await _database.ref('${AppConstants.dbOrders}/${order.id}/status').get();
    final latestStatus = statusSnap.value?.toString();
    if (latestStatus == 'Delivered' || latestStatus == 'Cancelled') {
      return;
    }

    await _database.ref('${AppConstants.dbOrders}/${order.id}').update({
      'status': 'Delivered',
      'paymentStatus': 'Paid',
      'deliveredAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
