import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import ini
import 'pages/login_page.dart';
import 'pages/main_stock_app.dart'; // Pastikan file ini sudah dibuat

void main() async {
  // Pastikan plugin Flutter sudah diinisialisasi sebelum menjalankan SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cek keberadaan token
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('auth_token');

  runApp(MyApp(initialToken: token));
}

class MyApp extends StatelessWidget {
  final String? initialToken;
  
  const MyApp({super.key, this.initialToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Ganti ke orange jika ingin mengikuti warna header screenshot awal
        colorSchemeSeed: Colors.orange, 
      ),
      // Jika token ada, langsung ke MainNavigationPage, jika tidak ke LoginPage
      home: initialToken != null && initialToken!.isNotEmpty
          ? const MainNavigationPage() 
          : const LoginPage(),
    );
  }
}