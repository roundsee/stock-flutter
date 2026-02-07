import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddItemPage extends StatefulWidget {
  const AddItemPage({super.key});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  
  String _selectedType = 'Bahan'; // Default value
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    bool success = await ApiService().addItem(
      code: _codeController.text,
      name: _nameController.text,
      type: _selectedType,
      unit: _unitController.text,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Material berhasil ditambahkan!')),
        );
        Navigator.pop(context, true); // Kembali ke halaman sebelumnya dengan sinyal refresh
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menambah material. Cek koneksi/kode item.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Input Material Baru")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(labelText: "Kode Item", border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Kode tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Nama Material", border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Nama tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(labelText: "Satuan (Contoh: Kg, Pcs, Box)", border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Satuan wajib diisi' : null,
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(labelText: "Jenis Material", border: OutlineInputBorder()),
                    items: ['Bahan', 'Produk'].map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedType = val!),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      onPressed: _submit,
                      child: const Text("SIMPAN DATA"),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}