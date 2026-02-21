import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // To navigate to HomePage
import '../widgets/glass_container.dart';

class CalibrationScreen extends StatefulWidget {
  final bool isOnboarding;

  const CalibrationScreen({super.key, this.isOnboarding = false});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  // Accelerometer
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  double _currentMagnitude = 0.0;
  double _maxMagnitude = 0.0;

  // Microphone
  StreamSubscription<NoiseReading>? _noiseSubscription;
  NoiseMeter? _noiseMeter;
  double _currentDb = 0.0;
  double _maxDb = 0.0;

  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _startTesting() async {
    // Request Mic Permission
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Microphone permission required for calibration.')),
        );
      }
      return;
    }

    setState(() {
      _isTesting = true;
      _maxMagnitude = 0.0;
      _maxDb = 0.0;
    });

    // Start Accelerometer
    _accelSubscription =
        accelerometerEventStream().listen((AccelerometerEvent event) {
      double magnitude =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (mounted) {
        setState(() {
          _currentMagnitude = magnitude;
          if (magnitude > _maxMagnitude) _maxMagnitude = magnitude;
        });
      }
    });

    // Start Microphone
    try {
      _noiseMeter = NoiseMeter();
      _noiseSubscription = _noiseMeter?.noise.listen((NoiseReading reading) {
        if (mounted) {
          setState(() {
            _currentDb = reading.maxDecibel;
            if (reading.maxDecibel > _maxDb) _maxDb = reading.maxDecibel;
          });
        }
      }, onError: (Object e) {
        debugPrint(e.toString());
      });
    } catch (e) {
      debugPrint("Failed to start noise meter: $e");
    }
  }

  void _stopTesting() {
    _accelSubscription?.cancel();
    _noiseSubscription?.cancel();
    setState(() {
      _isTesting = false;
    });
  }

  Future<void> _saveBaselineAndFinish() async {
    // Calculate a safe baseline from the peaks, ensuring it falls within UI limits
    double shakeLimit = (_maxMagnitude * 0.8).clamp(10.0, 30.0);
    double soundLimit = (_maxDb * 0.9).clamp(50.0, 100.0);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('shake_sensitivity', shakeLimit);
    await prefs.setDouble('sound_sensitivity', soundLimit);

    if (widget.isOnboarding) {
      await prefs.setBool('has_onboarded', true);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Custom baselines saved successfully!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _stopTesting();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Sensor Calibration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  opacity: 0.1,
                  border: Border.all(color: Colors.white10),
                  child: const Text(
                    'Test your device\'s hardware here to set accurate thresholds on the home screen. Shake your phone and shout to see your maximum baseline capabilities.',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 30),

                // Accelerometer Card
                _buildSensorCard(
                  title: "ACCELEROMETER (Motion)",
                  currentValue: '${_currentMagnitude.toStringAsFixed(1)} m/s²',
                  maxValue: 'Peak: ${_maxMagnitude.toStringAsFixed(1)}',
                  icon: Icons.vibration,
                  color: Colors.blueAccent,
                  progress: (_currentMagnitude / 50.0)
                      .clamp(0.0, 1.0), // Assuming 50 m/s^2 is max
                ),

                const SizedBox(height: 20),

                // Microphone Card
                _buildSensorCard(
                  title: "MICROPHONE (Sound)",
                  currentValue: '${_currentDb.toStringAsFixed(1)} dB',
                  maxValue: 'Peak: ${_maxDb.toStringAsFixed(1)}',
                  icon: Icons.mic,
                  color: Colors.orangeAccent,
                  progress: (_currentDb / 120.0)
                      .clamp(0.0, 1.0), // Assuming 120 dB is max
                ),

                const Spacer(),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isTesting ? Colors.grey[800] : const Color(0xFFE53935),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isTesting ? _stopTesting : _startTesting,
                  child: Text(
                    _isTesting
                        ? 'STOP TEST'
                        : (_maxMagnitude == 0.0
                            ? 'START CALIBRATION TEST'
                            : 'RETRY TEST'),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),

                // Show save button only if a test has been run
                if (!_isTesting && (_maxMagnitude > 0 || _maxDb > 0))
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _saveBaselineAndFinish,
                    child: Text(
                      widget.isOnboarding
                          ? 'SAVE BASELINE & FINISH'
                          : 'UPDATE BASELINE',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSensorCard({
    required String title,
    required String currentValue,
    required String maxValue,
    required IconData icon,
    required Color color,
    required double progress,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      opacity: 0.05,
      border: Border.all(color: Colors.white12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                ],
              ),
              Text(
                maxValue,
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Center(
            child: Text(
              currentValue,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
