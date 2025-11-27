import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../main.dart'; // PENTING: Import main.dart untuk akses themeNotifier

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedMusicApp = 'spotify';
  
  // Ganti boolean jadi String untuk support 3 mode: 'system', 'light', 'dark'
  String _themeMode = 'system'; 

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  void _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedMusicApp = prefs.getString('music_app') ?? 'spotify';
      _themeMode = prefs.getString('theme_mode') ?? 'system';
    });
  }

  void _saveMusicPreference(String appKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('music_app', appKey);
    setState(() {
      _selectedMusicApp = appKey;
    });
  }

  void _saveThemePreference(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode);
    
    // Update Notifier Global agar main.dart merespon perubahan
    themeNotifier.value = mode;

    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Cek apakah mode gelap aktif (untuk styling halaman ini saja)
    bool isDarkUI = Theme.of(context).brightness == Brightness.dark;
    
    final textColor = isDarkUI ? AppColors.textSecondary : Colors.black54;
    final cardColor = isDarkUI ? AppColors.surface : Colors.white;
    final iconColor = isDarkUI ? Colors.white : Colors.black87;
    final borderColor = isDarkUI ? Colors.transparent : Colors.grey.shade300;

    return Scaffold(
      appBar: AppBar(title: const Text("PENGATURAN")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Aplikasi Musik Default", style: TextStyle(color: textColor, fontSize: 14)),
            const SizedBox(height: 10),
            _buildOptionItem(
              title: "Spotify", 
              isSelected: _selectedMusicApp == 'spotify',
              icon: Icons.music_note,
              onTap: () => _saveMusicPreference('spotify'),
              cardColor: cardColor, iconColor: iconColor, borderColor: borderColor,
            ),
            const SizedBox(height: 10),
            _buildOptionItem(
              title: "YouTube Music", 
              isSelected: _selectedMusicApp == 'ytmusic',
              icon: Icons.play_circle_filled,
              onTap: () => _saveMusicPreference('ytmusic'),
              cardColor: cardColor, iconColor: iconColor, borderColor: borderColor,
            ),

            const SizedBox(height: 30),

            Text("Tampilan Aplikasi", style: TextStyle(color: textColor, fontSize: 14)),
            const SizedBox(height: 10),

            // --- PILIHAN TEMA (Dropdown Style) ---
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _buildThemeRadio("Ikuti Sistem", "system", Icons.settings_brightness, iconColor),
                  const Divider(height: 1),
                  _buildThemeRadio("Mode Gelap", "dark", Icons.dark_mode, iconColor),
                  const Divider(height: 1),
                  _buildThemeRadio("Mode Terang", "light", Icons.light_mode, iconColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeRadio(String title, String value, IconData icon, Color iconColor) {
    return RadioListTile<String>(
      title: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(color: iconColor, fontWeight: FontWeight.w500)),
        ],
      ),
      value: value,
      groupValue: _themeMode,
      activeColor: AppColors.primary,
      onChanged: (val) {
        if (val != null) _saveThemePreference(val);
      },
    );
  }

  Widget _buildOptionItem({
    required String title, 
    required bool isSelected, 
    required IconData icon,
    required VoidCallback onTap,
    required Color cardColor,
    required Color iconColor,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : borderColor,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: TextStyle(color: iconColor, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}