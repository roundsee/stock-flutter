import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/item_model.dart';

class PengeluaranPage extends StatefulWidget {
  const PengeluaranPage({super.key});

  @override
  State<PengeluaranPage> createState() => _PengeluaranPageState();
}

class _PengeluaranPageState extends State<PengeluaranPage> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _noteController = TextEditingController(); // Controller untuk keterangan
  
  List<ItemStock> _items = [];
  List<dynamic> _gudangs = [];
  
  int? _selectedItemId;
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
        _items = items;
        _gudangs = gudangs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error memuat data: $e")),
        );
      }
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || _selectedItemId == null || _selectedGudangId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap isi semua kolom!")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Memanggil API Service Pengeluaran
    bool success = await ApiService().storePengeluaran(
      itemId: _selectedItemId!,
      gudangId: _selectedGudangId!,
      jumlah: int.parse(_qtyController.text),
      keterangan: _noteController.text,
    );

    setState(() => _isSubmitting = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pengeluaran berhasil dicatat!")),
        );
        Navigator.pop(context, true); // Kembali ke Home & trigger refresh
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mencatat pengeluaran. Cek stok atau koneksi.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Input Pengeluaran (Keluar)"),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const Text("Detail Barang & Lokasi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),

                  // Dropdown Pilih Barang
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: "Pilih Barang", border: OutlineInputBorder()),
                    items: _items.map<DropdownMenuItem<int>>((ItemStock item) {
                      return DropdownMenuItem<int>(
                        value: item.id,
                        child: Text("${item.itemName} (Stok: ${item.currentStock})"),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedItemId = val),
                  ),
                  const SizedBox(height: 15),

                  // Dropdown Pilih Gudang
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: "Pilih Gudang", border: OutlineInputBorder()),
                    items: _gudangs.map<DropdownMenuItem<int>>((dynamic gudang) {
                      return DropdownMenuItem<int>(
                        value: int.parse(gudang['id'].toString()),
                        child: Text(gudang['nama_gudang'] ?? 'Gudang'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedGudangId = val),
                  ),
                  const SizedBox(height: 15),

                  // Input Jumlah
                  TextFormField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Jumlah Keluar", border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Jumlah wajib diisi' : null,
                  ),
                  const SizedBox(height: 15),

                  // Input Keterangan
                  TextFormField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Keterangan / Alasan", 
                      border: OutlineInputBorder(),
                      hintText: "Contoh: Pemakaian Internal / Rusak",
                    ),
                    validator: (v) => v!.isEmpty ? 'Keterangan wajib diisi' : null,
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("SIMPAN PENGELUARAN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}