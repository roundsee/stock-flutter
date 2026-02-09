import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/item_model.dart';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';


class StockReportPage extends StatefulWidget {
  const StockReportPage({super.key});

  @override
  State<StockReportPage> createState() => _StockReportPageState();
}

class _StockReportPageState extends State<StockReportPage> {
  List<ItemStock> _allStocks = []; // Data asli dari API
  List<ItemStock> _filteredStocks = []; // Data yang ditampilkan setelah filter
  List<dynamic> _gudangs = [];
  
  bool _isLoading = true;

  // Variabel Filter
  String _searchName = "";
  int? _selectedGudangId;
  double _minQty = 0;
  double _maxQty = 1000; // Default max tinggi
  String? _selectedType; // null berarti "Semua", atau isi dengan "Produk"/"Bahan"

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    try {
      final stocks = await ApiService().getStockReport();
      if (stocks.isNotEmpty) {
    // Intip isi tipe barang dari database kamu di console
    print("Tipe Barang dari DB: '${stocks[0].itemType}'"); 
  }
      final gudangs = await ApiService().getGudangs();
      setState(() {
        _allStocks = stocks;
        _filteredStocks = stocks;
        _gudangs = gudangs;
        _isLoading = false;
      });
    } catch (e) {
      print("ERROR LOAD DATA: $e"); // Ini akan muncul di console VS Code
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Gagal memuat data: $e")),
    );
    }
  }

  // LOGIKA FILTER
 void _runFilter() {
  List<ItemStock> results = [];
  
  results = _allStocks.where((item) {
    // 1. Filter Nama/Produk
    final matchName = item.itemName.toLowerCase().contains(_searchName.toLowerCase());
    
    // 2. Filter Tipe (Produk vs Bahan)
    // Misal Anda punya variabel String? _selectedType ('Produk' atau 'Bahan')
    final matchType = _selectedType == null ||item.itemType.toLowerCase() == _selectedType!.toLowerCase();;
    
    // 3. Filter Gudang
    final matchGudang = _selectedGudangId == null || item.gudangId == _selectedGudangId;
    
    // 4. Filter Range Qty
    final matchQty = item.currentStock >= _minQty && item.currentStock <= _maxQty;

    return matchName && matchType && matchGudang && matchQty;
  }).toList();
print("Filter Aktif: $_selectedType");
  if (_allStocks.isNotEmpty) {
     print("Contoh tipe dari API: '${_allStocks[0].itemType}'");
  }
  setState(() {
    _filteredStocks = results;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
      onPressed: _exportToExcel,
      label: const Text("Export Excel"),
      icon: const Icon(Icons.description),
      backgroundColor: Colors.green[700],
    ),
      body: Column(
        children: [
          _buildFilterPanel(), // Panel Filter di atas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async => _loadData(),
                    child: _buildList(),
                  ),
          ),
        ],
      ),
    );
  }

Widget _buildFilterPanel() {
  return Card(
    margin: const EdgeInsets.all(10),
    elevation: 2,
    child: ExpansionTile(
      leading: const Icon(Icons.filter_alt, color: Colors.blue),
      title: const Text("Filter Stok"),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Column(
            children: [
              // Search Nama
              TextField(
                decoration: const InputDecoration(
                  labelText: "Nama Barang",
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (val) {
                  _searchName = val;
                  _runFilter();
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Dropdown Kategori (Produk/Bahan)
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(labelText: "Tipe"),
                      items: const [
                        DropdownMenuItem(value: null, child: Text("Semua")),
                        DropdownMenuItem(value: "Produk", child: Text("Produk")),
                        DropdownMenuItem(value: "Bahan", child: Text("Bahan")),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedType = val);
                        _runFilter();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Dropdown Gudang
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedGudangId,
                      decoration: const InputDecoration(labelText: "Gudang"),
                      items: [
                        const DropdownMenuItem(value: null, child: Text("Semua")),
                        ..._gudangs.map((g) => DropdownMenuItem(value: g['id'], child: Text(g['nama_gudang']))),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedGudangId = val);
                        _runFilter();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Filter Range Qty
              Text("Rentang Qty: ${_minQty.toInt()} - ${_maxQty.toInt()}"),
              RangeSlider(
                values: RangeValues(_minQty, _maxQty),
                min: 0,
                max: 1000,
                divisions: 20,
                onChanged: (values) {
                  setState(() {
                    _minQty = values.start;
                    _maxQty = values.end;
                  });
                  _runFilter();
                },
              ),
              _buildResetButton(), // Tombol Reset muncul di sini
            ],
          ),
        )
      ],
    ),
  );
}
Widget _buildResetButton() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextButton.icon(
      onPressed: () {
        setState(() {
          // Kembalikan semua ke default
          _searchName = "";
          _selectedGudangId = null;
          _selectedType = null;
          _minQty = 0.0;
          _maxQty = 1000.0;
          _filteredStocks = _allStocks; // Tampilkan semua lagi
        });
      },
      icon: const Icon(Icons.refresh, color: Colors.orange),
      label: const Text("Reset Filter", style: TextStyle(color: Colors.orange)),
    ),
  );
}

  Widget _buildList() {
    if (_filteredStocks.isEmpty) {
      return const Center(child: Text("Data tidak ditemukan"));
    }
    return ListView.builder(
      itemCount: _filteredStocks.length,
      itemBuilder: (context, index) {
        final item = _filteredStocks[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            title: Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Gudang: ${item.gudangName ?? 'Default'}"),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${item.currentStock}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: item.currentStock <= 5 ? Colors.red : Colors.blue,
                  ),
                ),
                const Text("Unit", style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
        );
      },
    );
  }

Future<void> _exportToExcel() async {
  if (_filteredStocks.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Tidak ada data untuk diekspor")),
    );
    return;
  }

  // Tampilkan loading sebentar
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Stock Report'];

    // 1. Header dengan format CellValue terbaru
    sheetObject.appendRow([
      TextCellValue("Kode Barang"),
      TextCellValue("Nama Barang"),
      TextCellValue("Tipe"),
      TextCellValue("Gudang"),
      TextCellValue("Stok Saat Ini"),
      TextCellValue("Satuan"),
    ]);

    // 2. Isi Data dari _filteredStocks
    for (var item in _filteredStocks) {
      sheetObject.appendRow([
        TextCellValue(item.itemCode ?? "-"),
        TextCellValue(item.itemName),
        TextCellValue(item.itemType),
        TextCellValue(item.gudangName ?? "Default"),
        DoubleCellValue(item.currentStock.toDouble()), // Gunakan Double untuk angka
        TextCellValue(item.unit ?? ""),
      ]);
    }

    // 3. Simpan File
    final directory = await getApplicationDocumentsDirectory();
    final String filePath = "${directory.path}/Stock_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";
    
    final fileBytes = excel.save();
    if (fileBytes != null) {
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
      
      // Tutup loading
      Navigator.pop(context);

      // 4. Buka File
      
    }
  } catch (e) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Gagal ekspor: $e")),
    );
  }
}  
}