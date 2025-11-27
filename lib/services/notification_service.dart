import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // --- Fungsi Inisialisasi ---
  Future<void> init() async {
    // 1. Setup Timezone (Wajib untuk jadwal)
    tz.initializeTimeZones();
    // Set lokasi default ke Jakarta agar waktu akurat
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (e) {
      print("Error setting location: $e");
    }

    // 2. Setup Icon Android
    // Pastikan file 'ic_launcher.png' ada di folder:
    // android/app/src/main/res/mipmap-*/ic_launcher.png
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. Setup iOS
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true);

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Minta Izin Notifikasi (Khusus Android 13+)
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    }
  }

  // --- Fungsi Jadwal Notifikasi Harian ---
  Future<void> scheduleDailyNotification() async {
    // Pastikan menggunakan lokasi waktu lokal (Asia/Jakarta sudah di-set di init)
    final now = tz.TZDateTime.now(tz.local);
    
    // Tentukan jam 16:00 (4 Sore) hari ini
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      16, 
      0, 
    );

    // Jika jam 16:00 sudah lewat, jadwalkan untuk besok
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, // ID Notifikasi
      'Waktunya Cek Motor!', // Judul
      'Jangan lupa update Kilometermu di menu Cek Oli ya!', // Isi Pesan
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel', // ID Channel unik
          'Pengingat Harian', // Nama Channel terlihat user
          channelDescription: 'Mengingatkan update kilometer setiap sore',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // --- PARAMETER PENTING VERSI TERBARU ---
      // 1. Mode Jadwal Android (Pengganti androidAllowWhileIdle)
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      
      // 2. Interpretasi Waktu (Wajib Ada)
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
          
      // 3. Ulangi Setiap Hari pada jam yang sama
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}