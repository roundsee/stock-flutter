import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item_model.dart';

class ApiService {
  // Gunakan 10.0.2.2 untuk emulator Android, atau IP asli laptop untuk HP fisik
  final String baseUrl = "http://10.0.2.2:8000/api";

  //final String baseUrl = "http://IP_LAPTOP_KAMU:8000/api";
 // final String token = "PASTE_TOKEN_DARI_VSCODE_KAMU_DI_SINI";

Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['access_token']);
        return data['access_token']; // Mengembalikan token jika sukses
      } else {
        return null; // Login gagal
      }
    } catch (e) {
      return null;
    }
  }

  // Di dalam class ApiService

Future<bool> logout() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    // Tetap panggil API untuk kebersihan di server
    await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 5)); // Tambahkan timeout agar tidak nunggu kelamaan

  } catch (e) {
    print("Logout API error: $e");
    // Lanjut ke penghapusan token lokal meskipun API error
  } finally {
    // Apapun yang terjadi, hapus token di HP
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  return true; // Selalu kembalikan true agar UI bisa pindah halaman
}

  

  Future<List<ItemStock>> getStockReport() async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('auth_token');

  final response = await http.get(
    Uri.parse('$baseUrl/items/stock-report'),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );
print("Response Status: ${response.statusCode}");
print("Response Body: ${response.body}");

  if (response.statusCode == 200) {
    List jsonResponse = json.decode(response.body);
    return jsonResponse.map((data) => ItemStock.fromJson(data)).toList();
  } else {
    throw Exception('Gagal mengambil data stok');
  }
}

// Di dalam class ApiService

Future<bool> addItem({
  required String code,
  required String name,
  required String type,
  required String unit,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    final response = await http.post(
      Uri.parse('$baseUrl/items'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'item_code': code,
        'item_name': name,
        'item_type': type,
        'unit': unit,
      }),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  } catch (e) {
    print("Add Item Error: $e");
    return false;
  }
}

// Di dalam class ApiService

// 1. Ambil daftar gudang untuk Dropdown
Future<List<dynamic>> getGudangs() async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('auth_token');

  final response = await http.get(
    Uri.parse('$baseUrl/gudangs'),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Gagal mengambil data gudang');
  }
}

// 2. Kirim data Penerimaan
// Di dalam class ApiService

Future<Map<String, dynamic>> storePenerimaan({
  required int itemId,
  required int gudangId,
  required int jumlah,
  String keterangan = "Penerimaan dari App",
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    final response = await http.post(
      Uri.parse('$baseUrl/penerimaan'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "gudang_id": gudangId,
        "keterangan": keterangan,
        "items": [
          {"item_id": itemId, "qty": jumlah}
        ]
      }),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {"success": true, "message": "Berhasil"};
    } else {
      // Ambil pesan error dari Laravel (misal: 'Stok tidak cukup' atau 'Validation error')
      String errorMessage = responseData['message'] ?? "Terjadi kesalahan server (${response.statusCode})";
      return {"success": false, "message": errorMessage};
    }
  } catch (e) {
    return {"success": false, "message": "Gagal terhubung ke server. Cek koneksi Anda."};
  }
}

Future<bool> storePengeluaran({
  required int itemId,
  required int gudangId,
  required int jumlah,
  required String keterangan,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    final response = await http.post(
      Uri.parse('$baseUrl/pengeluaran'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "gudang_id": gudangId,
        "keterangan": keterangan,
        "items": [
          {"item_id": itemId, "qty": jumlah}
        ]
      }),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  } catch (e) {
    return false;
  }
}
}