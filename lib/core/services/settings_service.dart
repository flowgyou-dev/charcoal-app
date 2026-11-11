import 'package:firebase_database/firebase_database.dart';
import '../constants/app_constants.dart';
import '../models/shop_settings_model.dart';

class SettingsService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Stream<ShopSettings> get settingsStream {
    return _database.ref(AppConstants.dbSettings).onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        return ShopSettings.fromMap(event.snapshot.value as Map<dynamic, dynamic>);
      }
      return const ShopSettings();
    });
  }

  Future<ShopSettings> getSettings() async {
    final snap = await _database.ref(AppConstants.dbSettings).get();
    if (snap.exists && snap.value is Map) {
      return ShopSettings.fromMap(snap.value as Map<dynamic, dynamic>);
    }
    return const ShopSettings();
  }
}
