import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'gesture_service.dart';
import 'sound_service.dart';
import 'alert_screen.dart';
import 'screens/log_viewer_screen.dart';

void main() {
  runApp(const ShakeAlertApp());
}

class ShakeAlertApp extends StatelessWidget {
  const ShakeAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nirapotta Safety',
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
      home: const HomePage(),
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

  @override
  void initState() {
    super.initState();
    _gestureService = GestureService(
      onGestureDetected: _onGestureDetected,
      shakeThreshold: _shakeSensitivity,
    );

    _soundService = SoundService(
      onLoudNoiseDetected: _onLoudNoiseDetected,
    );
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

  void _triggerAlert(String reason) {
    // STOP LISTENING IMMEDIATELY to prevent infinite loops
    _gestureService.stopListening();
    _soundService.stopListening();
    setState(() {
      _isListening = false;
    });

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

  void _updateSensitivity(double value) {
    setState(() {
      _shakeSensitivity = value;
      _gestureService.shakeThreshold = _shakeSensitivity;
    });
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
      appBar: AppBar(
        title: const Text('Nirapotta Safety V3'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.data_usage),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const LogViewerScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Safety Disclaimer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.amber.shade700),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'AI Active: Monitoring sensors for falls, impacts, and distress signals.',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
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
                glowColor:
                    _isListening ? const Color(0xFFE53935) : Colors.transparent,
                duration: const Duration(milliseconds: 2000),
                repeat: true,
                child: GestureDetector(
                  onTap: _toggleListening,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening
                          ? const Color(0xFFE53935)
                          : const Color(0xFF2C2C2C),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                      border: Border.all(
                        color: _isListening ? Colors.redAccent : Colors.white12,
                        width: 4,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isListening
                              ? Icons.security
                              : Icons.power_settings_new,
                          size: 60,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _isListening ? 'ARMED' : 'TAP TO\nACTIVATE',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Sensitivity Slider (Modern)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SENSOR SENSITIVITY',
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
                            color: Colors.redAccent),
                      ),
                    ],
                  ),
                  Slider(
                    value: _shakeSensitivity,
                    min: 10.0,
                    max: 30.0,
                    divisions: 20,
                    activeColor: const Color(0xFFE53935),
                    inactiveColor: Colors.white10,
                    label: _shakeSensitivity.toStringAsFixed(1),
                    onChanged: _isListening ? null : _updateSensitivity,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
