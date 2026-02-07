import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
        future: ApiService().getStockLogs(), // Pastikan method ini ada di ApiService
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada riwayat transaksi"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final log = snapshot.data![index];
              final bool isMasuk = log['jenis'] == 'masuk';
              
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Baris 1: Nomor Referensi & Badge Jenis
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            log['referensi_no'],
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isMasuk ? Colors.green.shade100 : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              isMasuk ? "MASUK" : "KELUAR",
                              style: TextStyle(
                                color: isMasuk ? Colors.green.shade800 : Colors.red.shade800,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      
                      // Baris 2: Nama Barang
                      Text(
                        log['item']['item_name'] ?? 'Barang tidak diketahui',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      // Baris 3: Detail Perhitungan Stok
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStockColumn("Awal", log['stok_awal'].toString(), Colors.black54),
                          Icon(isMasuk ? Icons.add : Icons.remove, size: 16),
                          _buildStockColumn("Qty", log['qty'].toString(), isMasuk ? Colors.green : Colors.red),
                          const Icon(Icons.drag_handle, size: 16),
                          _buildStockColumn("Akhir", log['stok_akhir'].toString(), Colors.blue, isBold: true),
                        ],
                      ),
                      
                      const SizedBox(height: 10),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(log['created_at'])),
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
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

  Widget _buildStockColumn(String label, String value, Color color, {bool isBold = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 15, 
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color
          ),
        ),
      ],
    );
  }
}