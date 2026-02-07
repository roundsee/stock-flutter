import 'package:flutter/material.dart';
import 'stock_report_page.dart';
import 'penerimaan_page.dart';
import 'pengeluaran_page.dart';
import 'add_item_page.dart';
import 'setting_page.dart';
import 'history_page.dart'; // Import halaman history yang kita buat tadi
import '../services/api_service.dart'; // Import ApiService

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  bool _isServerOn = true; // Variabel status server

  @override
  void initState() {
    super.initState();
    _checkApiStatus(); // Cek status saat aplikasi dibuka
  }

  // Fungsi cek koneksi ke Laravel
  void _checkApiStatus() async {
    bool status = await ApiService().checkConnection();
    if (mounted) {
      setState(() => _isServerOn = status);
    }
  }

  List<Widget> _getPages() {
    return [
      const StockReportPage(),
      const HistoryPage(), // Pasang HistoryPage di sini
      const SettingsPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Gudang Digital",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
        // --- TAMBAHKAN INDIKATOR DI SINI ---
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Tooltip(
              message: _isServerOn ? "Server Online" : "Server Offline",
              child: Icon(
                Icons.circle,
                size: 14,
                color: _isServerOn ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _checkApiStatus();
              setState(() {}); // Refresh halaman aktif
            },
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _getPages(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () => _showActionSheet(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "Stok"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Riwayat"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Setelan"),
        ],
      ),
    );
  }

  // ... (Method _showActionSheet tetap sama seperti kode Anda)
  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.category, color: Colors.orange),
                title: const Text("Tambah Material Baru"),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddItemPage()),
                  );
                  if (result == true) setState(() {});
                },
              ),
              ListTile(
                leading: const Icon(Icons.download, color: Colors.green),
                title: const Text("Penerimaan Barang (Masuk)"),
                onTap: () async {
                  Navigator.pop(context);
                  if (!_isServerOn) {
                    _showOfflineSnippet();
                    return;
                  }
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PenerimaanPage()),
                  );
                  if (result == true) setState(() {});
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload, color: Colors.red),
                title: const Text("Pengeluaran Barang (Keluar)"),
                onTap: () async {
                  Navigator.pop(context);
                  if (!_isServerOn) {
                    _showOfflineSnippet();
                    return;
                  }
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PengeluaranPage()),
                  );
                  if (result == true) setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOfflineSnippet() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Tidak dapat transaksi. Server sedang Offline!"),
        backgroundColor: Colors.red,
      ),
    );
  }
}