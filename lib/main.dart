import 'package:flutter/material.dart';
// 1. TAMBAHKAN IMPORT INI (Wajib untuk format tanggal)
import 'package:intl/date_symbol_data_local.dart'; 

import 'screens/auth_check_screen.dart';

// 2. UBAH main() MENJADI async
void main() async {
  // 3. Pastikan binding flutter siap sebelum menjalankan kode async
  WidgetsFlutterBinding.ensureInitialized();

  // 4. Inisialisasi data bahasa Indonesia ('id_ID')
  // Ini yang mencegah error layar merah saat membuka Kalender
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To Do Me',
      theme: ThemeData(
        primarySwatch: Colors.lightGreen, // Tema kamu tetap terjaga
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,

      // Arahkan 'home' ke AuthCheckScreen (sesuai kode aslimu)
      home: const AuthCheckScreen(), 
    );
  }
}