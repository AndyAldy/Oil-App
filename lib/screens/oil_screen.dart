import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import '../constants.dart';

class OilScreen extends StatefulWidget {
  const OilScreen({super.key});

  @override
  State<OilScreen> createState() => _OilScreenState();
}

class _OilScreenState extends State<OilScreen> {
  final TextEditingController _kmController = TextEditingController();
  
  // Referensi Database
  final CollectionReference _bikes = FirebaseFirestore.instance.collection('bikes');
  final String _docId = 'my_motor'; // ID unik motor kamu

  // Variable Lokal (Default Value)
  int _currentKm = 0;
  int _lastEngineOilChangeKm = 0;
  final int _engineOilInterval = 2000;
  bool _isEngineLocked = false;

  int _lastGearOilChangeKm = 0;
  final int _gearOilInterval = 6000;
  bool _isGearLocked = false;

  bool _isLoading = true; // Indikator loading

  @override
  void initState() {
    super.initState();
    _loadDataFromFirebase();
  }

  // --- FUNGSI FIREBASE: LOAD DATA ---
  Future<void> _loadDataFromFirebase() async {
    try {
      DocumentSnapshot doc = await _bikes.doc(_docId).get();

      if (doc.exists) {
        // Jika data ada di Firebase, ambil datanya
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          _currentKm = data['currentKm'] ?? 0;
          _lastEngineOilChangeKm = data['lastEngineOilChangeKm'] ?? 0;
          _lastGearOilChangeKm = data['lastGearOilChangeKm'] ?? 0;
          _isEngineLocked = data['isEngineLocked'] ?? false;
          _isGearLocked = data['isGearLocked'] ?? false;
          _isLoading = false;
        });
      } else {
        // Jika data belum ada (pengguna baru), buat data default
        await _bikes.doc(_docId).set({
          'currentKm': 0,
          'lastEngineOilChangeKm': 0,
          'lastGearOilChangeKm': 0,
          'isEngineLocked': false,
          'isGearLocked': false,
        });
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
      setState(() => _isLoading = false);
    }
  }

  // --- FUNGSI FIREBASE: UPDATE DATA ---
  Future<void> _updateFirebase(Map<String, dynamic> dataToUpdate) async {
    try {
      await _bikes.doc(_docId).update(dataToUpdate);
    } catch (e) {
      debugPrint("Gagal update ke Firebase: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menyimpan data ke internet")),
      );
    }
  }

  // Getter Sisa Jarak
  int get _remainingEngineKm => (_lastEngineOilChangeKm + _engineOilInterval) - _currentKm;
  int get _remainingGearKm => (_lastGearOilChangeKm + _gearOilInterval) - _currentKm;

  // Fungsi Update Odometer (Simpan ke Firebase)
  void _updateOdometer() async {
    if (_kmController.text.isNotEmpty) {
      int newKm = int.parse(_kmController.text);
      
      // Update UI Lokal dulu biar cepat
      setState(() {
        _currentKm = newKm;
      });

      // Simpan ke Firebase
      await _updateFirebase({'currentKm': newKm});

      _kmController.clear();
      if (mounted) Navigator.pop(context);
    }
  }

  // Fungsi Reset Service (Simpan ke Firebase)
  void _resetService(String type) {
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text("Konfirmasi Ganti $type"),
        content: Text(
          "Apakah Anda baru saja mengganti $type?\n\nData akan diupdate ke $_currentKm KM.",
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              Map<String, dynamic> updateData = {};
              
              setState(() {
                if (type == "Oli Mesin") {
                  _lastEngineOilChangeKm = _currentKm;
                  _isEngineLocked = true;
                  updateData = {
                    'lastEngineOilChangeKm': _currentKm,
                    'isEngineLocked': true
                  };
                } else {
                  _lastGearOilChangeKm = _currentKm;
                  _isGearLocked = true;
                  updateData = {
                    'lastGearOilChangeKm': _currentKm,
                    'isGearLocked': true
                  };
                }
              });

              // Kirim Update ke Firebase
              await _updateFirebase(updateData);

              if (mounted) Navigator.pop(context);
            }, 
            child: const Text("Ya, Sudah Ganti", style: TextStyle(color: AppColors.primary))
          ),
        ],
      )
    );
  }

  // Fungsi Edit Manual (Simpan ke Firebase)
  void _showManualEditDialog(String title, int currentValue, Function(int) onSave, String fieldName) {
    _kmController.text = currentValue.toString();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text("Set Awal $title"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Masukkan KM servis terakhir.", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: _kmController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(filled: true, fillColor: Colors.black12, suffixText: "KM"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              if (_kmController.text.isNotEmpty) {
                int val = int.parse(_kmController.text);
                onSave(val); // Update State Lokal
                
                // Update Firebase
                await _updateFirebase({fieldName: val});

                _kmController.clear();
                if (mounted) Navigator.pop(context);
              }
            }, 
            child: const Text("Simpan", style: TextStyle(color: AppColors.primary))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("MONITORING OLI")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // KARTU ODOMETER
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("ODOMETER SAAT INI", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text("$_currentKm KM", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      _kmController.clear();
                      _showUpdateDialog(context);
                    },
                    icon: const Icon(Icons.edit, color: AppColors.primary),
                    style: IconButton.styleFrom(backgroundColor: Colors.white10),
                  )
                ],
              ),
            ),

            // KARTU OLI MESIN
            _buildOilCard(
              title: "OLI MESIN",
              icon: Icons.oil_barrel,
              remainingKm: _remainingEngineKm,
              lastChange: _lastEngineOilChangeKm,
              interval: _engineOilInterval,
              isLocked: _isEngineLocked,
              onReset: () => _resetService("Oli Mesin"),
              onEditLastChange: () {
                _showManualEditDialog("Ganti Terakhir (Mesin)", _lastEngineOilChangeKm, (val) {
                  setState(() => _lastEngineOilChangeKm = val);
                }, 'lastEngineOilChangeKm');
              },
            ),

            const SizedBox(height: 20),

            // KARTU OLI GARDAN
            _buildOilCard(
              title: "OLI GARDAN",
              icon: Icons.settings_suggest,
              remainingKm: _remainingGearKm,
              lastChange: _lastGearOilChangeKm,
              interval: _gearOilInterval,
              isLocked: _isGearLocked,
              onReset: () => _resetService("Oli Gardan"),
              onEditLastChange: () {
                _showManualEditDialog("Ganti Terakhir (Gardan)", _lastGearOilChangeKm, (val) {
                  setState(() => _lastGearOilChangeKm = val);
                }, 'lastGearOilChangeKm');
              },
            ),
          ],
        ),
      ),
    );
  }

  // ... (Widget _buildOilCard, _buildMiniInfo, dan _showUpdateDialog SAMA PERSIS dengan sebelumnya)
  // Silakan copy widget UI tersebut dari jawaban sebelumnya agar kode tidak terlalu panjang di sini.
  // Pastikan widget _buildOilCard menerima parameter isLocked.
  
  Widget _buildOilCard({
    required String title,
    required IconData icon,
    required int remainingKm,
    required int lastChange,
    required int interval,
    required bool isLocked,
    required VoidCallback onReset,
    required VoidCallback onEditLastChange,
  }) {
    Color statusColor = remainingKm < 500 ? AppColors.primary : Colors.green;
    String statusText = remainingKm < 0 
        ? "TERLAMBAT ${remainingKm.abs()} KM" 
        : "Sisa $remainingKm KM lagi";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniInfo(
                "Ganti Terakhir", 
                "$lastChange KM", 
                isEditable: !isLocked, 
                onTap: onEditLastChange
              ),
              _buildMiniInfo("Interval", "$interval KM"),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                foregroundColor: statusColor,
              ),
              child: const Text("SUDAH GANTI BARU (RESET)"),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMiniInfo(String label, String value, {bool isEditable = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: isEditable ? onTap : null,
      child: Container(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                if (isEditable) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.edit, size: 12, color: AppColors.primary),
                ]
              ],
            ),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Update Odometer"),
        content: TextField(
          controller: _kmController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: "Masukkan KM di speedometer",
            filled: true,
            fillColor: Colors.black12,
            suffixText: "KM"
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(onPressed: _updateOdometer, child: const Text("Update", style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
  }
}