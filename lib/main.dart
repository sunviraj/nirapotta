import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'gesture_service.dart';
import 'sound_service.dart';
import 'camera_service.dart'; // Added for Evidence Capture
import 'data/sensor_repository.dart'; // Added for data storage access
import 'package:shared_preferences/shared_preferences.dart'; // Added for custom thresholds
import 'alert_screen.dart';
import 'screens/log_viewer_screen.dart';
import 'screens/calibration_screen.dart';
import 'screens/splash_screen.dart'; // Added for Onboarding
import 'widgets/glass_container.dart'; // Added for Glassmorphism

void main() {
  runApp(const ShakeAlertApp());
}

class ShakeAlertApp extends StatelessWidget {
  const ShakeAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nirapotta ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE53935), // Safety Red
          surface: Color(0xFF1E1E1E),
          onSurface: Colors.white,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      home: const SplashScreen(), // Starts the Onboarding Flow
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late GestureService _gestureService;
  late SoundService _soundService;

  bool _isListening = false;
  double _shakeSensitivity = 15.0; // Default threshold
  double _soundSensitivity = 85.0; // Default mic threshold

  @override
  void initState() {
    super.initState();
    _loadCustomPreferences();

    _gestureService = GestureService(
      onGestureDetected: _onGestureDetected,
      shakeThreshold: _shakeSensitivity,
    );

    _soundService = SoundService(
      onLoudNoiseDetected: _onLoudNoiseDetected,
      dbThreshold: _soundSensitivity,
    );
  }

  Future<void> _loadCustomPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _shakeSensitivity = prefs.getDouble('shake_sensitivity') ?? 15.0;
        _soundSensitivity = prefs.getDouble('sound_sensitivity') ?? 85.0;

        // Update services with loaded custom thresholds immediately
        _gestureService.shakeThreshold = _shakeSensitivity;
        _soundService.dbThreshold = _soundSensitivity;
      });
    }
  }

  void _onGestureDetected(GestureType type) {
    if (!mounted) return;

    String triggerType =
        type == GestureType.IMPACT ? "IMPACT DETECTED" : "SHAKE DETECTED";
    _triggerAlert(triggerType);
  }

  void _onLoudNoiseDetected() {
    if (!mounted) return;
    _triggerAlert("LOUD NOISE DETECTED");
  }

  void _triggerAlert(String reason) async {
    // STOP LISTENING IMMEDIATELY to prevent infinite loops
    _gestureService.stopListening();
    _soundService.stopListening();

    // Store reason for CSV filename
    SensorDataRepository().lastTriggerReason = reason;

    // EVIDENCE CAPTURE (Saiful)
    // Trigger camera for Major Alerts (Impact or Loud Noise)
    if (reason.contains("IMPACT") || reason.contains("LOUD NOISE")) {
      debugPrint("Major Alert Detected: Capturing Evidence...");
      try {
        await CameraService().takeEvidencePhoto(reason);
      } catch (e) {
        debugPrint("Failed to capture evidence: $e");
      }
    }

    setState(() {
      _isListening = false;
    });

    if (!mounted) return;

    // Navigate to alert screen with the reason
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => AlertScreen(triggerReason: reason)),
    );
  }

  void _toggleListening() async {
    if (_isListening) {
      _gestureService.stopListening();
      _soundService.stopListening();
      setState(() {
        _isListening = false;
      });
    } else {
      _gestureService.startListening();
      await _soundService.startListening(); // Request mic permission
      setState(() {
        _isListening = true;
      });
    }
  }

  void _updateSensitivity(double value) async {
    setState(() {
      _shakeSensitivity = value;
      _gestureService.shakeThreshold = _shakeSensitivity;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('shake_sensitivity', value);
  }

  void _updateSoundSensitivity(double value) async {
    setState(() {
      _soundSensitivity = value;
      _soundService.dbThreshold = _soundSensitivity;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sound_sensitivity', value);
  }

  @override
  void dispose() {
    _gestureService.stopListening();
    _soundService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            'Nirapotta Safety V3',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          centerTitle: true,
          backgroundColor: Colors.black.withValues(alpha: 0.3),
          elevation: 0,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune), // Calibration Icon
              tooltip: 'Hardware Calibration',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const CalibrationScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.data_usage),
              tooltip: 'Sensor Logs',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const LogViewerScreen()),
                );
              },
            ),
          ],
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
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Safety Disclaimer (Glass)
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      opacity: 0.1,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15)),
                      child: Row(
                        children: [
                          Icon(Icons.shield_outlined,
                              color: Colors.amber.shade400, size: 28),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'AI Active: Monitoring sensors for falls, impacts, and distress signals.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Status Indicator with Pulsing Animation
                    Center(
                      child: AvatarGlow(
                        animate: _isListening,
                        glowColor: _isListening
                            ? const Color(0xFFE53935)
                            : Colors.blueGrey,
                        duration: const Duration(milliseconds: 2000),
                        repeat: true,
                        child: GestureDetector(
                          onTap: _toggleListening,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: _isListening
                                    ? [
                                        const Color(0xFFFF5252),
                                        const Color(0xFFD32F2F)
                                      ]
                                    : [
                                        const Color(0xFF37474F),
                                        const Color(0xFF263238)
                                      ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _isListening
                                      ? Colors.redAccent.withValues(alpha: 0.4)
                                      : Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                )
                              ],
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isListening
                                      ? Icons.security
                                      : Icons.power_settings_new,
                                  size: 50,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _isListening ? 'ARMED' : 'TAP TO\nACTIVATE',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Dual Sensitivity Sliders (Glass)
                    GlassContainer(
                      padding: const EdgeInsets.all(20),
                      opacity: 0.05,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Shake Slider
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'MOTION SENSITIVITY',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white54),
                              ),
                              Text(
                                '${_shakeSensitivity.toStringAsFixed(1)} m/s²',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent),
                              ),
                            ],
                          ),
                          Slider(
                            value: _shakeSensitivity,
                            min: 10.0,
                            max: 30.0,
                            divisions: 20,
                            activeColor: Colors.blueAccent,
                            inactiveColor: Colors.white10,
                            label: _shakeSensitivity.toStringAsFixed(1),
                            onChanged: _isListening ? null : _updateSensitivity,
                          ),
                          const SizedBox(height: 10),
                          // Mic Slider
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'MIC SENSITIVITY (dB)',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white54),
                              ),
                              Text(
                                '${_soundSensitivity.toStringAsFixed(1)} dB',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orangeAccent),
                              ),
                            ],
                          ),
                          Slider(
                            value: _soundSensitivity,
                            min: 50.0,
                            max: 100.0,
                            divisions: 50,
                            activeColor: Colors.orangeAccent,
                            inactiveColor: Colors.white10,
                            label: _soundSensitivity.toStringAsFixed(1),
                            onChanged:
                                _isListening ? null : _updateSoundSensitivity,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            )));
  }
}
