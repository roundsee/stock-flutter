import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../services/api_service.dart';

class StockReportPage extends StatefulWidget {
  const StockReportPage({super.key});

  @override
  State<StockReportPage> createState() => _StockReportPageState();
}

class _StockReportPageState extends State<StockReportPage> {
  // Key ini digunakan untuk memaksa FutureBuilder memuat ulang data
  Key _refreshKey = UniqueKey();

  // Fungsi untuk memicu refresh dari dalam widget ini
  Future<void> _handleRefresh() async {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Kita hilangkan Scaffold karena sudah ada di MainNavigationPage
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: FutureBuilder<List<ItemStock>>(
        // Key diletakkan di sini. Jika Key berubah, FutureBuilder akan reset
        key: _refreshKey,
        future: ApiService().getStockReport(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 10),
                  Text('Gagal memuat data: ${snapshot.error}'),
                  TextButton(
                    onPressed: _handleRefresh,
                    child: const Text("Coba Lagi"),
                  )
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return ListView( // Gunakan ListView agar RefreshIndicator tetap bekerja saat kosong
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                const Center(child: Text('Stok kosong melompong')),
              ],
            );
          }

          return ListView.builder(
            // Penting: tambahkan physics agar selalu bisa di-scroll untuk refresh
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var item = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  title: Row(
                    children: [
                      Text(
                        item.itemName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      _buildTypeBadge(item.itemType),
                    ],
                  ),
                  subtitle: Text("Kode: ${item.itemCode}"),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${item.currentStock}",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _getStockColor(item.currentStock),
                        ),
                      ),
                      Text(
                        item.unit,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper untuk warna stok
  Color _getStockColor(int stock) {
    if (stock <= 0) return Colors.red;
    if (stock < 5) return Colors.orange;
    return Colors.green;
  }

  // Helper untuk badge tipe (Bahan/Produk)
  Widget _buildTypeBadge(String type) {
    bool isProduct = type.toLowerCase() == 'produk';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isProduct ? Colors.purple.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isProduct ? Colors.purple.shade200 : Colors.blue.shade200,
        ),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 10,
          color: isProduct ? Colors.purple.shade900 : Colors.blue.shade900,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}