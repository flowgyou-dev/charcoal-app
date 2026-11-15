class AppConstants {
  static const String appName = 'CharCoal Express';
  static const String currencySymbol = '₱';

  // Realtime Database Nodes
  static const String dbInventory = 'inventory';
  static const String dbInventoryHistory = 'inventory_history';
  static const String dbOrders = 'orders';
  static const String dbOrderReceipts = 'order_receipts';
  static const String dbUsedReceiptRefs = 'used_receipt_refs';
  static const String dbDrivers = 'drivers';
  static const String dbDriverLocations = 'driver_locations';
  static const String dbUsers = 'users';
  static const String dbSettings = 'settings';

  // Default Hub coordinates (1055 Hardinan, Barangay Lamot 2, Calauan, Laguna)
  static const double defaultHubLat = 14.1489;
  static const double defaultHubLng = 121.3156;
  static const String defaultHubAddress =
      '1055 Hardinan, Barangay Lamot 2, Calauan, Laguna';
}
