import 'package:firebase_database/firebase_database.dart';
import '../models/order_model.dart';
import '../services/receipt_ocr_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/shop_settings_model.dart';
import '../../../core/utils/validators.dart';

class OrderService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// Places a real order using authoritative RTDB inventory & settings,
  /// validates anti-reuse receipt references for Online QR payments,
  /// and atomically reserves stock via RTDB transaction.
  Future<CharcoalOrder> placeOrder({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
    required double deliveryLat,
    required double deliveryLng,
    required int sacksOrdered,
    required String paymentMethod, // 'COD' | 'ONLINE_QR'
    ReceiptScanResult? scannedReceipt,
  }) async {
    if (sacksOrdered < 1 || sacksOrdered > 1000) {
      throw Exception('Order quantity must be between 1 and 1000.');
    }

    final cleanAddress = Validators.sanitizeText(deliveryAddress);
    if (cleanAddress.length < 10) {
      throw Exception('Please complete your Delivery Address (at least 10 characters).');
    }

    final isOnline = paymentMethod == 'ONLINE_QR';
    String? refKey;
    if (isOnline) {
      if (scannedReceipt == null || scannedReceipt.refNumber.isEmpty) {
        throw Exception('Please upload and scan your payment receipt via OCR.');
      }
      refKey = ReceiptOcrParser.normalizeRefKey(scannedReceipt.refNumber);
      if (refKey.length < 4) {
        throw Exception('Invalid OCR Reference Number.');
      }
      final dupSnap = await _database.ref('${AppConstants.dbUsedReceiptRefs}/$refKey').get();
      if (dupSnap.exists) {
        throw Exception(
          'This Reference Number (${scannedReceipt.refNumber}) has already been used on another order. Please upload a new receipt.',
        );
      }
    }

    // 1. Fetch authoritative price & delivery settings from RTDB
    final invSnap = await _database.ref(AppConstants.dbInventory).get();
    if (!invSnap.exists || invSnap.value is! Map) {
      throw Exception('Charcoal Inventory record not found in database.');
    }
    final invMap = invSnap.value as Map<dynamic, dynamic>;
    final unitPrice = double.tryParse(invMap['pricePerUnit']?.toString() ?? '') ?? 0;
    if (unitPrice <= 0) {
      throw Exception('Invalid product unit price in database.');
    }

    final settingsSnap = await _database.ref(AppConstants.dbSettings).get();
    final settings = settingsSnap.exists && settingsSnap.value is Map
        ? ShopSettings.fromMap(settingsSnap.value as Map<dynamic, dynamic>)
        : const ShopSettings();

    final deliveryFee = settings.calculateDeliveryFee(
      destLat: deliveryLat,
      destLng: deliveryLng,
    );
    final subtotal = (sacksOrdered * unitPrice).roundToDouble();
    final total = (subtotal + deliveryFee).roundToDouble();

    // 2. Atomically reserve/deduct stock via RTDB transaction
    final stockRef = _database.ref('${AppConstants.dbInventory}/currentStock');
    bool insufficientStock = false;
    int availableOnFailure = 0;

    final txResult = await stockRef.runTransaction((Object? current) {
      final currentStock = int.tryParse(current?.toString() ?? '0') ?? 0;
      if (currentStock < sacksOrdered) {
        insufficientStock = true;
        availableOnFailure = currentStock;
        return Transaction.abort();
      }
      return Transaction.success(currentStock - sacksOrdered);
    });

    if (insufficientStock) {
      throw Exception('Insufficient stock! Only $availableOnFailure sack(s) remaining.');
    }
    if (!txResult.committed) {
      throw Exception('Could not reserve stock due to a concurrent order. Please try again.');
    }

    final newStock = int.tryParse(txResult.snapshot.value?.toString() ?? '0') ?? 0;
    await _database.ref('${AppConstants.dbInventory}/lastUpdated').set(DateTime.now().toIso8601String());

    final orderRef = _database.ref(AppConstants.dbOrders).push();
    final orderId = orderRef.key ?? 'ORD-${DateTime.now().millisecondsSinceEpoch}';

    final order = CharcoalOrder(
      id: orderId,
      customerId: customerId,
      customerName: Validators.sanitizeText(customerName),
      customerPhone: customerPhone.trim(),
      deliveryAddress: cleanAddress,
      deliveryLat: deliveryLat,
      deliveryLng: deliveryLng,
      sacksOrdered: sacksOrdered,
      pricePerUnit: unitPrice,
      subtotalAmount: subtotal,
      deliveryFee: deliveryFee,
      totalAmount: total,
      paymentMethod: isOnline ? 'ONLINE_QR' : 'COD',
      paymentStatus: isOnline ? 'Pending Verification' : 'Unpaid',
      receiptRefNumber: isOnline ? scannedReceipt!.refNumber : null,
      ocrDetectedAmount: isOnline ? scannedReceipt!.detectedAmount : null,
      hasReceipt: isOnline,
      status: 'Pending',
      createdAt: DateTime.now().toIso8601String(),
    );

    try {
      await orderRef.set(order.toMap());

      if (isOnline && scannedReceipt != null && refKey != null) {
        await _database.ref('${AppConstants.dbOrderReceipts}/$orderId').set({
          'orderId': orderId,
          'customerId': customerId,
          'imageBase64': scannedReceipt.imageBase64DataUrl,
          'ocrRefNumber': scannedReceipt.refNumber,
          'ocrAmount': scannedReceipt.detectedAmount,
          'ocrRawSnippet': scannedReceipt.rawSnippet,
          'uploadedAt': DateTime.now().toIso8601String(),
        });

        await _database.ref('${AppConstants.dbUsedReceiptRefs}/$refKey').set({
          'orderId': orderId,
          'customerId': customerId,
          'refNumber': scannedReceipt.refNumber,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      await _database.ref(AppConstants.dbInventoryHistory).push().set({
        'type': 'ORDER_DEDUCTION',
        'quantity': sacksOrdered,
        'reason': 'Order $orderId by ${order.customerName}',
        'newBalance': newStock,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Compensating stock rollback if order write failed after reservation
      await stockRef.runTransaction((Object? current) {
        final cur = int.tryParse(current?.toString() ?? '0') ?? 0;
        return Transaction.success(cur + sacksOrdered);
      });
      rethrow;
    }

    return order;
  }

  /// Allows customer to cancel a Pending order and atomically restores stock & releases receipt ref.
  Future<void> cancelOrder(CharcoalOrder order, {String reason = 'Cancelled by Customer'}) async {
    final statusSnap = await _database.ref('${AppConstants.dbOrders}/${order.id}/status').get();
    final latestStatus = statusSnap.value?.toString() ?? order.status;
    if (latestStatus != 'Pending') {
      throw Exception('Order can no longer be cancelled because its status is already "$latestStatus".');
    }

    await _database.ref('${AppConstants.dbOrders}/${order.id}').update({
      'status': 'Cancelled',
      'cancelReason': Validators.sanitizeText(reason).isEmpty ? 'Cancelled by Customer' : Validators.sanitizeText(reason),
      'cancelledAt': DateTime.now().toIso8601String(),
    });

    final stockRef = _database.ref('${AppConstants.dbInventory}/currentStock');
    final txRes = await stockRef.runTransaction((Object? current) {
      final cur = int.tryParse(current?.toString() ?? '0') ?? 0;
      return Transaction.success(cur + order.sacksOrdered);
    });
    final restoredBalance = int.tryParse(txRes.snapshot.value?.toString() ?? '0') ?? 0;

    await _database.ref('${AppConstants.dbInventory}/lastUpdated').set(DateTime.now().toIso8601String());
    await _database.ref(AppConstants.dbInventoryHistory).push().set({
      'type': 'CANCELLATION_RESTORE',
      'quantity': order.sacksOrdered,
      'reason': 'Customer cancelled ${order.id}: $reason',
      'newBalance': restoredBalance,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (order.receiptRefNumber != null && order.receiptRefNumber!.isNotEmpty) {
      final refKey = ReceiptOcrParser.normalizeRefKey(order.receiptRefNumber!);
      if (refKey.isNotEmpty) {
        await _database.ref('${AppConstants.dbUsedReceiptRefs}/$refKey').remove();
      }
    }
  }

  // Stream Customer Orders
  Stream<List<CharcoalOrder>> streamCustomerOrders(String customerId) {
    return _database
        .ref(AppConstants.dbOrders)
        .orderByChild('customerId')
        .equalTo(customerId)
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

  // Stream Live Driver Location for Order
  Stream<Map<String, double>?> streamDriverLocation(String driverId) {
    return _database.ref('${AppConstants.dbDriverLocations}/$driverId').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value is! Map) return null;
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
