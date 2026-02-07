import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/item_model.dart';

class PengeluaranPage extends StatefulWidget {
  const PengeluaranPage({super.key});

  @override
  State<PengeluaranPage> createState() => _PengeluaranPageState();
}

class _PengeluaranPageState extends State<PengeluaranPage> {
  final _qtyController = TextEditingController();
  final _noteController = TextEditingController();
  
  List<ItemStock> _itemsMaster = []; 
  List<dynamic> _gudangs = [];
  List<Map<String, dynamic>> _selectedItems = []; 
  
  int? _selectedItemId;
  String? _selectedItemName;
  int? _currentAvailableStock = 0; // Untuk validasi input
  int? _selectedGudangId;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    try {
      final items = await ApiService().getStockReport();
      final gudangs = await ApiService().getGudangs();
      setState(() {
        _itemsMaster = items;
        _gudangs = gudangs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _addItemToList() {
    int inputQty = int.tryParse(_qtyController.text) ?? 0;

    if (_selectedItemId == null || inputQty <= 0) {
      _showSnackBar("Pilih barang dan isi jumlah valid!");
      return;
    }

    // Validasi sederhana di sisi Client (biar user tidak salah input)
    if (inputQty > _currentAvailableStock!) {
      _showSnackBar("Stok tidak mencukupi! (Tersedia: $_currentAvailableStock)");
      return;
    }

    setState(() {
      _selectedItems.add({
        "item_id": _selectedItemId,
        "item_name": _selectedItemName,
        "qty": inputQty,
      });
      _qtyController.clear();
      _selectedItemId = null;
      _currentAvailableStock = 0;
    });
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _submit() async {
    if (_selectedItems.isEmpty || _selectedGudangId == null || _noteController.text.isEmpty) {
      _showSnackBar("Lengkapi gudang, keterangan, dan daftar barang!");
      return;
    }

    setState(() => _isSubmitting = true);

    // Kirim data ke API Multi-Item
    final result = await ApiService().storePengeluaranMulti(
      gudangId: _selectedGudangId!,
      keterangan: _noteController.text,
      items: _selectedItems,
    );

    setState(() => _isSubmitting = false);

    if (result['success']) {
      if (mounted) {
        _showSnackBar("Pengeluaran berhasil dicatat!");
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        _showErrorDialog(result['message']);
      }
    }
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Gagal Simpan"),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pengeluaran Multi-Item"), backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // HEADER
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: "Pilih Lokasi Gudang Keluar"),
                  items: _gudangs.map((g) => DropdownMenuItem<int>(value: g['id'], child: Text(g['nama_gudang']))).toList(),
                  onChanged: (val) => setState(() => _selectedGudangId = val),
                ),
                TextField(controller: _noteController, decoration: const InputDecoration(labelText: "Keterangan (Contoh: Proyek A / Rusak)")),
                const Divider(height: 30),

                // INPUT ITEM
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButton<int>(
                        isExpanded: true,
                        hint: const Text("Pilih Barang"),
                        value: _selectedItemId,
                        items: _itemsMaster.map((item) => DropdownMenuItem(
                          value: item.id, 
                          child: Text("${item.itemName} (Sisa: ${item.currentStock})")
                        )).toList(),
                        onChanged: (val) {
                          final item = _itemsMaster.firstWhere((e) => e.id == val);
                          setState(() {
                            _selectedItemId = val;
                            _selectedItemName = item.itemName;
                            _currentAvailableStock = item.currentStock;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: "Qty"),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: Colors.red.shade700, size: 35),
                      onPressed: _addItemToList,
                    )
                  ],
                ),

                const SizedBox(height: 20),
                const Align(alignment: Alignment.centerLeft, child: Text("Barang yang akan dikeluarkan:", style: TextStyle(fontWeight: FontWeight.bold))),
                
                // LIST DAFTAR BARANG SEMENTARA
                // Ganti bagian Expanded yang berisi daftar barang di PengeluaranPage
Expanded(
  child: ListView.builder(
    itemCount: _selectedItems.length,
    itemBuilder: (context, index) {
      final item = _selectedItems[index];
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.red.shade100, // Warna merah untuk pengeluaran
            child: Text("${index + 1}", style: const TextStyle(fontSize: 12, color: Colors.red)),
          ),
          title: Text(item['item_name']),
          subtitle: Text("Jumlah Keluar: ${item['qty']} Unit"),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              setState(() {
                _selectedItems.removeAt(index);
              });
            },
          ),
        ),
      );
    },
  ),
),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                    onPressed: _isSubmitting ? null : _submit,
                    child: const Text("PROSES PENGELUARAN"),
                  ),
                )
              ],
            ),
          ),
    );
  }
}