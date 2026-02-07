import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/item_model.dart';

class PenerimaanPage extends StatefulWidget {
  const PenerimaanPage({super.key});

  @override
  State<PenerimaanPage> createState() => _PenerimaanPageState();
}

class _PenerimaanPageState extends State<PenerimaanPage> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  
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
      // Ambil data barang (menggunakan fungsi yang sudah Anda buat sebelumnya)
      final items = await ApiService().getStockReport();
      // Ambil data gudang
      final gudangs = await ApiService().getGudangs();

      setState(() {
        _items = items;
        _gudangs = gudangs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error memuat data: $e")),
      );
    }
  }

  void _submit() async {
  if (!_formKey.currentState!.validate() || _selectedItemId == null || _selectedGudangId == null) {
    return;
  }

  setState(() => _isSubmitting = true);

  // Ambil Map hasil dari API
  final result = await ApiService().storePenerimaan(
    itemId: _selectedItemId!,
    gudangId: _selectedGudangId!,
    jumlah: int.parse(_qtyController.text),
  );

  setState(() => _isSubmitting = false);

  if (result['success'] == true) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Penerimaan Berhasil!"), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    }
  } else {
    // Tampilkan pesan error ASLI dari Laravel
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Gagal Simpan"),
          content: Text(result['message']), // PESAN ERROR DI SINI
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Input Penerimaan")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Dropdown Pilih Barang
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: "Pilih Barang", border: OutlineInputBorder()),
                    items: _items.map((item) {
                      return DropdownMenuItem(value: item.id, child: Text(item.itemName));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedItemId = val),
                  ),
                  const SizedBox(height: 15),

                  // Dropdown Pilih Gudang
                  DropdownButtonFormField<int>(
  decoration: const InputDecoration(labelText: "Pilih Gudang", border: OutlineInputBorder()),
  value: _selectedGudangId,
  items: _gudangs.map<DropdownMenuItem<int>>((dynamic gudang) { // Tambahkan <DropdownMenuItem<int>>
    return DropdownMenuItem<int>(
      value: int.parse(gudang['id'].toString()), // Paksa jadi int
      child: Text(gudang['nama_gudang']),
    );
  }).toList(),
  onChanged: (val) => setState(() => _selectedGudangId = val),
),
                  const SizedBox(height: 15),

                  // Input Jumlah
                  TextFormField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Jumlah Masuk", border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Jumlah wajib diisi' : null,
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("SIMPAN PENERIMAAN"),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}