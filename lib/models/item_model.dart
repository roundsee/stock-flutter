class ItemStock {
  final int id;
  final String itemCode;
  final String itemName;
  final String itemType;
  final String unit;
  final int currentStock;


  ItemStock({
    required this.id,
    required this.itemCode,
    required this.itemName,
    required this.itemType,
    required this.unit,
    required this.currentStock,
  
  });

  // Fungsi untuk konversi dari JSON Laravel ke Object Dart
factory ItemStock.fromJson(Map<String, dynamic> json) {
  return ItemStock(
    id: json['id'] ?? 0,
    itemCode: json['item_code'] ?? '-',
    itemName: json['item_name'] ?? 'Tanpa Nama',
    // Gunakan operator ?? untuk memberikan nilai default jika null
    itemType: json['item_type'] ?? 'Bahan', 
    unit: json['unit'] ?? 'pcs',
    currentStock: json['current_stock'] != null 
        ? int.parse(json['current_stock'].toString()) 
        : 0,
  );
}
}