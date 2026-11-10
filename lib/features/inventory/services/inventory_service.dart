import 'package:firebase_database/firebase_database.dart';
import '../models/inventory_model.dart';
import '../../../core/constants/app_constants.dart';

class InventoryService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Stream<CharcoalInventory> get inventoryStream {
    return _database.ref(AppConstants.dbInventory).onValue.map((event) {
      if (event.snapshot.exists) {
        return CharcoalInventory.fromMap(event.snapshot.value as Map<dynamic, dynamic>);
      }
      return CharcoalInventory(
        itemName: 'Standard Charcoal Sack (Uling)',
        currentStock: 120,
        pricePerUnit: 250.0,
        lowStockLimit: 20,
        unit: 'sack',
      );
    });
  }

  Future<CharcoalInventory> getInventory() async {
    final snap = await _database.ref(AppConstants.dbInventory).get();
    if (snap.exists) {
      return CharcoalInventory.fromMap(snap.value as Map<dynamic, dynamic>);
    }
    return CharcoalInventory(
      itemName: 'Standard Charcoal Sack (Uling)',
      currentStock: 120,
      pricePerUnit: 250.0,
      lowStockLimit: 20,
      unit: 'sack',
    );
  }
}
