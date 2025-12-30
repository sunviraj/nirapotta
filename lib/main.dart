import 'package:flutter/material.dart';
import 'shake_detector.dart';
import 'alert_screen.dart';

void main() {
  runApp(const ShakeAlertApp());
}

class ShakeAlertApp extends StatelessWidget {
  const ShakeAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shake Alert',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
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
  late ShakeDetector _shakeDetector;
  bool _isListening = false;
  double _sensitivity = 15.0; // Default threshold

  @override
  void initState() {
    super.initState();
    _shakeDetector = ShakeDetector(
      onShake: _onShakeDetected,
      threshold: _sensitivity,
    );
  }

  void _onShakeDetected() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AlertScreen()),
    );
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      if (_isListening) {
        _shakeDetector.startListening();
      } else {
        _shakeDetector.stopListening();
      }
    });
  }

  void _updateSensitivity(double value) {
    setState(() {
      _sensitivity = value;
      _shakeDetector.setThreshold(_sensitivity);
    });
  }

  @override
  void dispose() {
    _shakeDetector.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shake Alert Safety'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Safety Disclaimer
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade800),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'DISCLAIMER: This app is a simulation. It does NOT contact real emergency services. Use for testing and educational purposes only.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Status Indicator
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening ? Colors.green.shade100 : Colors.grey.shade200,
                  border: Border.all(
                    color: _isListening ? Colors.green : Colors.grey,
                    width: 4,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isListening ? Icons.security : Icons.security_update_warning,
                      size: 50,
                      color: _isListening ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isListening ? 'ARMED' : 'DISARMED',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isListening ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Sensitivity Slider
            const Text(
              'Shake Sensitivity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _sensitivity,
              min: 10.0,
              max: 30.0,
              divisions: 20,
              label: _sensitivity.toStringAsFixed(1),
              onChanged: _isListening ? null : _updateSensitivity,
            ),
            Text(
              'Threshold: ${_sensitivity.toStringAsFixed(1)} m/s²',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const Text(
              '(Lower = More Sensitive, Higher = Harder Shake)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Spacer(),

            // Start/Stop Button
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _toggleListening,
                icon: Icon(_isListening ? Icons.stop_circle : Icons.play_circle),
                label: Text(
                  _isListening ? 'STOP DETECTION' : 'START DETECTION',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isListening ? Colors.red : Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
