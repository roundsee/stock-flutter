import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/item_model.dart';

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
      final gudangs = await ApiService().getGudangs();
      setState(() {
        _allStocks = stocks;
        _filteredStocks = stocks;
        _gudangs = gudangs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
    final matchType = _selectedType == null || item.itemType == _selectedType;
    
    // 3. Filter Gudang
    final matchGudang = _selectedGudangId == null || item.gudangId == _selectedGudangId;
    
    // 4. Filter Range Qty
    final matchQty = item.currentStock >= _minQty && item.currentStock <= _maxQty;

    return matchName && matchType && matchGudang && matchQty;
  }).toList();

  setState(() {
    _filteredStocks = results;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
}