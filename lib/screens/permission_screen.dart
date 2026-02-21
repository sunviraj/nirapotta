import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'calibration_screen.dart'; // Route to Calibration instead of HomePage
import '../widgets/glass_container.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _micGranted = false;
  bool _cameraGranted = false;
  bool _storageGranted =
      false; // Using generic storage state, modern Android uses media scopes or doesn't need explicit runtime for public downloads if not heavily managed

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    _micGranted = await Permission.microphone.isGranted;
    _cameraGranted = await Permission.camera.isGranted;
    // For simple checking, we will assume true if we reach here and it's not strictly required on newer Androids,
    // but let's query the specific ones the app uses extensively.
    _storageGranted =
        await Permission.storage.isGranted || await Permission.photos.isGranted;
    setState(() {});
  }

  Future<void> _requestAll() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.camera,
      Permission.storage, // General placeholder
    ].request();

    setState(() {
      _micGranted = statuses[Permission.microphone] == PermissionStatus.granted;
      _cameraGranted = statuses[Permission.camera] == PermissionStatus.granted;

      // We don't mandate storage to be true because Android 13+ behaves differently with images vs files.
      // As long as they requested it, we move on.
    });

    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const CalibrationScreen(isOnboarding: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Setup Your Sentinel'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // Very Dark Slate
              Color(0xFF1E1E1E), // Dark Grey
              Color(0xFF2D1B2E), // Deep muted ruby
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Icon(Icons.privacy_tip_outlined,
                      size: 80, color: Colors.white54),
                  const SizedBox(height: 20),
                  Text(
                    'We Need Access',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Nirapotta functions entirely in the background. To detect emergencies and gather evidence autonomously, it requires the following core permissions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 40),
                  _buildPermissionItem(
                    icon: Icons.mic,
                    title: 'Microphone',
                    description:
                        'Required to detect loud screams or distress sounds. No audio is ever recorded or transmitted.',
                    isGranted: _micGranted,
                  ),
                  _buildPermissionItem(
                    icon: Icons.camera_alt,
                    title: 'Camera',
                    description:
                        'Required to silently capture photographic evidence during an active emergency.',
                    isGranted: _cameraGranted,
                  ),
                  _buildPermissionItem(
                    icon: Icons.folder,
                    title: 'Local Storage',
                    description:
                        'Required to safely store data logs and photos on your own device.',
                    isGranted:
                        _storageGranted, // May show false on Android 13+ but that's okay
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _requestAll,
                      child: Text(
                        'GRANT PERMISSIONS & START',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text('I will do this later',
                        style: TextStyle(color: Colors.white30)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
  }) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      opacity: 0.05,
      border: Border.all(
          color: isGranted
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isGranted
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: isGranted ? Colors.green : Colors.white54, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),
          if (isGranted)
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }
}
