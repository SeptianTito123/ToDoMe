import 'package:flutter/material.dart';
import 'screens/auth_check_screen.dart'; // <-- 1. Impor "Gerbang"

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To Do Me',
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,

      // 2. Arahkan 'home' ke AuthCheckScreen
      home: const AuthCheckScreen(), 
    );
  }
}