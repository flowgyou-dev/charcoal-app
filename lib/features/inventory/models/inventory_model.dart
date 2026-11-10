class CharcoalInventory {
  final String itemName;
  final int currentStock;
  final double pricePerUnit;
  final int lowStockLimit;
  final String unit;

  CharcoalInventory({
    required this.itemName,
    required this.currentStock,
    required this.pricePerUnit,
    required this.lowStockLimit,
    required this.unit,
  });

  factory CharcoalInventory.fromMap(Map<dynamic, dynamic> map) {
    return CharcoalInventory(
      itemName: map['itemName']?.toString() ?? 'Standard Charcoal Sack (Uling)',
      currentStock: int.tryParse(map['currentStock']?.toString() ?? '100') ?? 100,
      pricePerUnit: double.tryParse(map['pricePerUnit']?.toString() ?? '250.0') ?? 250.0,
      lowStockLimit: int.tryParse(map['lowStockLimit']?.toString() ?? '20') ?? 20,
      unit: map['unit']?.toString() ?? 'sack',
    );
  }
}
