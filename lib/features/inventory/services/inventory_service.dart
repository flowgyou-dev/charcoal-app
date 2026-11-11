import 'package:firebase_database/firebase_database.dart';
import '../models/inventory_model.dart';
import '../../../core/constants/app_constants.dart';

class InventoryService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Stream<CharcoalInventory?> get inventoryStream {
    return _database.ref(AppConstants.dbInventory).onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        return CharcoalInventory.fromMap(event.snapshot.value as Map<dynamic, dynamic>);
      }
      return null;
    });
  }

  Future<CharcoalInventory?> getInventory() async {
    final snap = await _database.ref(AppConstants.dbInventory).get();
    if (snap.exists && snap.value is Map) {
      return CharcoalInventory.fromMap(snap.value as Map<dynamic, dynamic>);
    }
    return null;
  }
}
