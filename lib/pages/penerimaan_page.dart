import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/item_model.dart';

class PenerimaanPage extends StatefulWidget {
  const PenerimaanPage({super.key});

  @override
  State<PenerimaanPage> createState() => _PenerimaanPageState();
}

class _PenerimaanPageState extends State<PenerimaanPage> {
  final _qtyController = TextEditingController();
  final _supplierController = TextEditingController();
  final _noteController = TextEditingController();
  
  List<ItemStock> _itemsMaster = []; // Data barang dari API
  List<dynamic> _gudangs = [];
  
  // "Keranjang" sementara untuk menampung banyak barang
  List<Map<String, dynamic>> _selectedItems = []; 
  
  int? _selectedItemId;
  String? _selectedItemName;
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

  // Fungsi untuk menambah barang ke daftar sementara
  void _addItemToList() {
    if (_selectedItemId == null || _qtyController.text.isEmpty) return;

    setState(() {
      _selectedItems.add({
        "item_id": _selectedItemId,
        "item_name": _selectedItemName,
        "qty": int.parse(_qtyController.text),
      });
      // Reset input barang setelah ditambah
      _qtyController.clear();
      _selectedItemId = null;
    });
  }

  void _submit() async {
    if (_selectedItems.isEmpty || _selectedGudangId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Daftar barang masih kosong!")));
      return;
    }

    setState(() => _isSubmitting = true);

    // Kirim data sesuai format Header-Detail Laravel
    bool success = await ApiService().storePenerimaanMulti(
      gudangId: _selectedGudangId!,
      supplier: _supplierController.text,
      keterangan: _noteController.text,
      items: _selectedItems, // Mengirim array items
    );

    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Penerimaan Multi-Item"), backgroundColor: Colors.green),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // BAGIAN HEADER
                TextField(controller: _supplierController, decoration: const InputDecoration(labelText: "Supplier")),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: "Pilih Gudang"),
                  items: _gudangs.map((g) => DropdownMenuItem<int>(value: g['id'], child: Text(g['nama_gudang']))).toList(),
                  onChanged: (val) => setState(() => _selectedGudangId = val),
                ),
                const Divider(height: 30),

                // BAGIAN INPUT BARANG (ITEM)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButton<int>(
                        isExpanded: true,
                        hint: const Text("Pilih Barang"),
                        value: _selectedItemId,
                        items: _itemsMaster.map((item) => DropdownMenuItem(
                          value: item.id, 
                          child: Text(item.itemName)
                        )).toList(),
                        onChanged: (val) {
                          final item = _itemsMaster.firstWhere((e) => e.id == val);
                          setState(() {
                            _selectedItemId = val;
                            _selectedItemName = item.itemName;
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
                      icon: const Icon(Icons.add_box, color: Colors.blue, size: 35),
                      onPressed: _addItemToList,
                    )
                  ],
                ),

                const SizedBox(height: 20),
                const Text("Daftar Barang yang Akan Masuk:", style: TextStyle(fontWeight: FontWeight.bold)),
                
                // DAFTAR BARANG (DETAIL)
                Expanded(
                  child: ListView.builder(
                    itemCount: _selectedItems.length,
    itemBuilder: (context, index) { // <--- Pastikan itemBuilder ada di sini
      final item = _selectedItems[index];
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Text("${index + 1}", style: const TextStyle(fontSize: 12)),
          ),
          title: Text(item['item_name']),
          subtitle: Text("Jumlah: ${item['qty']} Unit"),
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
    }, // <
                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: _isSubmitting ? null : _submit,
                    child: const Text("SIMPAN TRANSAKSI"),
                  ),
                )
              ],
            ),
          ),
    );
  }
}