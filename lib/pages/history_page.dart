import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';


class StockHistoryPage extends StatefulWidget {
  const StockHistoryPage({super.key});

  @override
  State<StockHistoryPage> createState() => _StockHistoryPageState();
}

class _StockHistoryPageState extends State<StockHistoryPage> {
  List<dynamic> _history = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Ganti dengan baseUrl kamu
  final String baseUrl = "https://stock.asta-tbk.com/api";

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('$baseUrl/stock-logs'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _history = data['data']; // Mengambil array dari key 'data'
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Gagal mengambil data (${response.statusCode})";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Terjadi kesalahan koneksi";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Stok"),
        actions: [
          IconButton(
    icon: const Icon(Icons.file_download),
    onPressed: () => exportToExcel(_history), // _history adalah data dari API tadi
  ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLogs,
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)));
    }

    if (_history.isEmpty) {
      return const Center(child: Text("Belum ada riwayat stok"));
    }

    return ListView.builder(
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final log = _history[index];
        final itemDetail = log['item']; // Detail barang (item_name, unit)
        final isMasuk = log['jenis'] == 'masuk';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: isMasuk ? Colors.green[50] : Colors.red[50],
              child: Icon(
                isMasuk ? Icons.add_business : Icons.local_shipping,
                color: isMasuk ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              itemDetail['item_name'] ?? 'Produk Tidak Dikenal',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text("Ref: ${log['referensi_no']}"),
                const SizedBox(height: 2),
                Text(
                  "Sisa: ${log['stok_akhir']} ${itemDetail['unit']}",
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
                Text(
                  log['created_at'].toString().substring(0, 10),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${isMasuk ? '+' : '-'}${log['qty']}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isMasuk ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  itemDetail['unit'] ?? '',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

Future<void> exportToExcel(List<dynamic> data) async {
  var excel = Excel.createExcel();
  Sheet sheetObject = excel['Laporan Stok'];

 // 1. Buat Header (Gunakan TextCellValue)
sheetObject.appendRow([
  TextCellValue("Tanggal"),
  TextCellValue("No Referensi"),
  TextCellValue("Nama Barang"),
  TextCellValue("Jenis"),
  TextCellValue("Qty"),
  TextCellValue("Satuan"),
  TextCellValue("Stok Akhir"),
]);

// 2. Masukkan Data dari API (Gunakan pembungkus yang sesuai)
for (var log in data) {
  sheetObject.appendRow([
    TextCellValue(log['created_at'].toString().substring(0, 10)),
    TextCellValue(log['referensi_no'].toString()),
    TextCellValue(log['item']['item_name'].toString()),
    TextCellValue(log['jenis'].toString()),
    IntCellValue(log['qty']), // Jika qty adalah angka
    TextCellValue(log['item']['unit'].toString()),
    IntCellValue(log['stok_akhir']), // Jika stok_akhir adalah angka
  ]);
}

  // 3. Simpan ke Folder Download/Dokumen
  var fileBytes = excel.save();
  Directory? directory = await getExternalStorageDirectory(); // Khusus Android
  String filePath = "${directory!.path}/Laporan_Stok_${DateTime.now().millisecondsSinceEpoch}.xlsx";

  File(filePath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(fileBytes!);

  // 4. Buka File secara otomatis

}  
}