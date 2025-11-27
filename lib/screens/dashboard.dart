import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../widgets/dashboard_card.dart';
import 'oil_screen.dart';
import 'settings_screen.dart';
import 'ai_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _motorName = "Ganti menjadi nama motormu"; // Nama Default

  @override
  void initState() {
    super.initState();
    _loadMotorName();
  }

  // Load nama dari penyimpanan
  void _loadMotorName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _motorName = prefs.getString('motor_name') ?? "Ganti menjadi nama motormu";
    });
  }

  // Simpan nama baru
  void _updateMotorName(String newName) async {
    if (newName.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('motor_name', newName);
      setState(() {
        _motorName = newName;
      });
    }
  }

  // Tampilkan Dialog Edit
  void _showEditNameDialog() {
    TextEditingController controller = TextEditingController(text: _motorName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Ganti Nama Motor"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Nama motor kesayangan...",
            filled: true,
            fillColor: Colors.black12,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              _updateMotorName(controller.text);
              Navigator.pop(context);
            },
            child: const Text("Simpan", style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // Fungsi membuka Google Maps
  Future<void> _launchMaps() async {
    final Uri googleMapsUrl = Uri.parse("google.navigation:q="); 
    final Uri browserUrl = Uri.parse("https://www.google.com/maps");

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);
      } else {
        await launchUrl(browserUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Gagal membuka maps: $e");
    }
  }

  // Fungsi membuka Musik
  Future<void> _launchMusic() async {
    final prefs = await SharedPreferences.getInstance();
    String app = prefs.getString('music_app') ?? 'spotify';
    
    Uri appUrl;
    if (app == 'spotify') {
      appUrl = Uri.parse("spotify:open"); 
    } else {
      appUrl = Uri.parse("https://music.youtube.com"); 
    }

    try {
      await launchUrl(appUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Gagal membuka musik: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Judul Header sekarang bisa diklik untuk diedit
        title: GestureDetector(
          onTap: _showEditNameDialog,
          child: Row(
            mainAxisSize: MainAxisSize.min, // Agar area sentuh pas di teks
            children: [
              const Icon(Icons.motorcycle, color: AppColors.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _motorName, 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.edit, size: 14, color: Colors.white54), // Ikon pensil kecil
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) {
                // Opsional: Refresh state jika ada settingan lain yang berubah
              });
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1, 
                children: [
                  DashboardCard(
                    icon: Icons.near_me,
                    title: "Navigasi",
                    subtitle: "Google Maps",
                    onTap: _launchMaps,
                  ),
                  DashboardCard(
                    icon: Icons.oil_barrel,
                    title: "Cek Oli",
                    isActive: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OilScreen()),
                      );
                    },
                  ),
                  DashboardCard(
                    icon: Icons.music_note,
                    title: "Musik",
                    subtitle: "Putar Lagu",
                    onTap: _launchMusic,
                  ),
                  DashboardCard(
                    icon: Icons.smart_toy_outlined, // Ikon Robot/AI
                    title: "Tanya AI",
                    subtitle: "Asisten Mekanik",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AiScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: AppColors.surface,
              child: const Center(
                child: Text(
                  "Tetap Fokus Saat Berkendara", 
                  style: TextStyle(color: AppColors.textSecondary)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}