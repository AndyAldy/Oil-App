import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'screens/dashboard.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/notification_service.dart';

// GANTI: Gunakan String notifier untuk 3 mode ('system', 'light', 'dark')
final ValueNotifier<String> themeNotifier = ValueNotifier('system');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.scheduleDailyNotification();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Gagal load .env: $e");
  }
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Gagal inisialisasi Firebase: $e");
  }

  final prefs = await SharedPreferences.getInstance();
  themeNotifier.value = prefs.getString('theme_mode') ?? 'system';

  runApp(const OilMonitorApp());
}

class OilMonitorApp extends StatelessWidget {
  const OilMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: themeNotifier,
      builder: (context, mode, child) {
        // Logika konversi String ke ThemeMode Flutter
        ThemeMode themeMode;
        if (mode == 'light') {
          themeMode = ThemeMode.light; // Paksa Terang
        } else if (mode == 'dark') {
          themeMode = ThemeMode.dark;  // Paksa Gelap
        } else {
          themeMode = ThemeMode.system; // Otomatis ikut HP
        }

        return MaterialApp(
          title: 'Monitoring Oli',
          debugShowCheckedModeBanner: false,
          // Pastikan kedua tema sudah didefinisikan di constants.dart
          theme: roadSyncLightTheme, 
          darkTheme: roadSyncTheme,  
          themeMode: themeMode, // Ini yang bikin otomatis berubah
          home: const HomeScreen(),
        );
      },
    );
  }
}