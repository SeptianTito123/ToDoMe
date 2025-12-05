import 'package:flutter/material.dart';

// 1. FORMAT TANGGAL
import 'package:intl/date_symbol_data_local.dart';

// 2. NOTIFICATION SERVICE
import 'services/notification_service.dart';

// 3. FIREBASE CORE & MESSAGING
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'screens/splash_screen.dart';

// ==========================================================
// ✅ HANDLER NOTIFIKASI SAAT APP MATI / BACKGROUND
// ==========================================================
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("🔔 Background Message: ${message.notification?.title}");
}

void main() async {
  // 4. PASTIKAN FLUTTER READY
  WidgetsFlutterBinding.ensureInitialized();

  // 5. INIT FIREBASE
  await Firebase.initializeApp();

  // 6. SET HANDLER BACKGROUND FCM
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  // 7. FORMAT TANGGAL INDONESIA
  await initializeDateFormatting('id_ID', null);

  // 8. REQUEST IZIN FCM (SATU KALI SAJA)
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // 9. AMBIL TOKEN FCM (LOG SAJA)
  final fcmToken = await FirebaseMessaging.instance.getToken();
  debugPrint("✅ FCM TOKEN: $fcmToken");

  runApp(const MyApp());
}

// ==========================================================
// ✅ ROOT APP
// ==========================================================
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();

    // ✅ INIT NOTIFIKASI LOCAL + FCM SETELAH CONTEXT TERSEDIA
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationService.init(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To Do Me',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,

      // Tetap SplashScreen
      home: const SplashScreen(),
    );
  }
}
