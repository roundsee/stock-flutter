class ItemStock {
  final int id;
  final String itemName;
  final String itemType;
  final int currentStock;
  final int? gudangId;      // Tambahkan ini
  final String? gudangName;  // Tambahkan ini

  ItemStock({
    required this.id,
    required this.itemName,
    required this.itemType,
    required this.currentStock,
    this.gudangId,          // Masukkan ke constructor
    this.gudangName,
  });

  factory ItemStock.fromJson(Map<String, dynamic> json) {
    return ItemStock(
      id: json['id'],
      itemName: json['item_name'],
      itemType: json['item_type'] ?? 'Produk', // Default Produk
      // Laravel mungkin mengirim qty sebagai string atau int, kita amankan ke int
      currentStock: int.parse(json['current_stock'].toString()),
      gudangId: json['gudang_id'],    // Pastikan key-nya sesuai dengan JSON API
      gudangName: json['gudang_name'], // Ambil nama gudang jika ada di JSON
    );
  }
}