import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:slide_to_act/slide_to_act.dart';

class AlertScreen extends StatefulWidget {
  final String triggerReason; // Added parameter

  const AlertScreen({
    super.key,
    this.triggerReason = "EMERGENCY DETECTED", // Default value
  });

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  bool _isStopping = false;

  @override
  void initState() {
    super.initState();
    _startAlarm();
  }

  Future<void> _startAlarm() async {
    // Check if we are already stopping before starting anything
    if (_isStopping || !mounted) return;

    // Play loud alert sound
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      if (_isStopping || !mounted) return; // Re-check
      await _audioPlayer.setSource(AssetSource('alert_sound.mp3'));
      if (_isStopping || !mounted) return; // Re-check
      await _audioPlayer.resume();
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }

    // Check again before vibrating
    if (_isStopping || !mounted) return;

    // Vibrate device
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(
          pattern: [500, 1000, 500, 2000],
          repeat: 0); // 0 means repeat indefinitely
    }
  }

  Future<void> _stopAlarm() async {
    _isStopping = true; // Set flag immediately
    await _audioPlayer.stop();
    await Vibration.cancel();
    debugPrint('Alarm stopped');
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    Vibration.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'EMERGENCY ALERT!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            // Display dynamic Trigger Reason
            Text(
              widget.triggerReason,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.yellowAccent,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            const Text(
              'Sending simulated alert...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),
            // Mock Emergency Options
            _buildMockOption(Icons.local_police, 'Call Police (Mock)'),
            _buildMockOption(Icons.local_hospital, 'Call Ambulance (Mock)'),
            _buildMockOption(Icons.message, 'Text Contacts (Mock)'),
            const Spacer(),
            // Slide to Stop (Modern Safety Feature)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: SlideAction(
                borderRadius: 30,
                elevation: 0,
                innerColor: Colors.red,
                outerColor: Colors.white,
                sliderButtonIcon: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                ),
                text: 'SLIDE TO DISABLE',
                textStyle: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                onSubmit: () async {
                  await _stopAlarm();
                  return null; // Reset slider? No, we pop.
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockOption(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 20),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
