import 'package:flutter/material.dart';
import 'stock_report_page.dart';
import 'penerimaan_page.dart';
import 'pengeluaran_page.dart';
import 'add_item_page.dart';
import 'setting_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  // Fungsi untuk mendapatkan daftar halaman
  // Kita jadikan method agar widget StockReportPage dibuat ulang saat setState dipanggil
  List<Widget> _getPages() {
    return [
      const StockReportPage(),                        // Index 0
      const Center(child: Text("History Transaksi")), // Index 1
      const SettingsPage(),                           // Index 2
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
      ),
      // Kita panggil method _getPages() di sini
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
              
              // MENU TAMBAH MATERIAL
              ListTile(
                leading: const Icon(Icons.category, color: Colors.orange),
                title: const Text("Tambah Material Baru"),
                onTap: () async {
                  Navigator.pop(context); // Tutup BottomSheet
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddItemPage()),
                  );
                  if (result == true) setState(() {}); // Refresh jika sukses
                },
              ),

              // MENU PENERIMAAN
              ListTile(
                leading: const Icon(Icons.download, color: Colors.green),
                title: const Text("Penerimaan Barang (Masuk)"),
                onTap: () async {
                  Navigator.pop(context); // Tutup BottomSheet
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PenerimaanPage()),
                  );
                  if (result == true) setState(() {}); // Refresh jika sukses
                },
              ),

              // MENU PENGELUARAN
              ListTile(
                leading: const Icon(Icons.upload, color: Colors.red),
                title: const Text("Pengeluaran Barang (Keluar)"),
                onTap: () async {
                  Navigator.pop(context); // Tutup BottomSheet
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PengeluaranPage()),
                  );
                  if (result == true) setState(() {}); // Refresh jika sukses
                },
              ),
            ],
          ),
        );
      },
    );
  }
}