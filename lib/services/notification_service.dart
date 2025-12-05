import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // ===========================================================
  // ✅ INIT UTAMA (LOCAL + FCM)
  // ===========================================================
  Future<void> init(BuildContext context) async {
    debugPrint("🔔 [NOTIF] INIT");

    // ============ TIMEZONE LOCAL ============
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    // ============ INIT LOCAL NOTIFICATION ============
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("✅ CLICK NOTIF LOCAL: ${details.payload}");
      },
    );

    await requestPermissions();
    await _initFCM(context);
  }

  // ===========================================================
  // ✅ PERMISSION ANDROID 13+
  // ===========================================================
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final android = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await android?.requestNotificationsPermission();
    }

    await _firebaseMessaging.requestPermission();
  }

  // ===========================================================
  // ✅ INIT FIREBASE NOTIFICATION
  // ===========================================================
  Future<void> _initFCM(BuildContext context) async {
    final token = await _firebaseMessaging.getToken();
    debugPrint("✅ FCM TOKEN: $token");

    // ✅ NOTIF MASUK SAAT APP DIBUKA (FOREGROUND)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? "Notifikasi";
      final body = message.notification?.body ?? "";

      _showForegroundNotification(title, body);
    });

    // ✅ NOTIF DITEKAN SAAT APP BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint("✅ NOTIF DIKLIK DARI BACKGROUND");
    });
  }

  // ===========================================================
  // ✅ TAMPILKAN NOTIFIKASI SAAT FOREGROUND
  // ===========================================================
  Future<void> _showForegroundNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'todome_fcm_alerts',
      'Notifikasi Server',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
    );
  }

  // ===========================================================
  // ✅ SCHEDULE NOTIFIKASI TUGAS (VERSI LAMA KAMU)
  // ===========================================================
  Future<void> scheduleTaskNotifications(
      int taskId, String title, DateTime deadline) async {
    final baseId = taskId * 1000;

    final now = tz.TZDateTime.now(tz.local);
    final tzDeadline = tz.TZDateTime.from(deadline, tz.local);

    await _schedule(baseId + 1, "H-7 Jam: $title",
        tzDeadline.subtract(const Duration(hours: 7)));
    await _schedule(baseId + 2, "H-1 Jam: $title",
        tzDeadline.subtract(const Duration(hours: 1)));
    await _schedule(baseId + 3, "H-30 Menit: $title",
        tzDeadline.subtract(const Duration(minutes: 30)));
    await _schedule(baseId + 4, "H-15 Menit: $title",
        tzDeadline.subtract(const Duration(minutes: 15)));
    await _schedule(baseId + 5, "H-10 Menit: $title",
        tzDeadline.subtract(const Duration(minutes: 10)));

    DateTime iterator = DateTime(now.year, now.month, now.day);

    int index = 0;
    while (iterator.isBefore(deadline)) {
      final pagi =
          tz.TZDateTime(tz.local, iterator.year, iterator.month, iterator.day, 7);
      final malam = tz.TZDateTime(
          tz.local, iterator.year, iterator.month, iterator.day, 19);

      await _schedule(baseId + 10 + index, "Pagi: $title", pagi);
      await _schedule(baseId + 11 + index, "Malam: $title", malam);

      index += 2;
      iterator = iterator.add(const Duration(days: 1));
    }
  }

  Future<void> _schedule(int id, String title, tz.TZDateTime time) async {
    final now = tz.TZDateTime.now(tz.local);
    if (time.isBefore(now)) return;

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        "",
        time,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'todome_task_alerts',
            'Pengingat Tugas',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint("✔ Scheduled ID $id at $time");
    } catch (e) {
      debugPrint("❌ Schedule error: $e");
    }
  }

  // ===========================================================
  // ✅ CANCEL SEMUA NOTIFIKASI TASK
  // ===========================================================
  Future<void> cancelTaskNotifications(int taskId) async {
    final baseId = taskId * 1000;
    for (int i = 0; i < 150; i++) {
      await flutterLocalNotificationsPlugin.cancel(baseId + i);
    }
  }
}
