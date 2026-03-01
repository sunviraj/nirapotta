import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../audio_recording_service.dart';
import '../camera_service.dart';

class BackgroundRecordingScreen extends StatefulWidget {
  const BackgroundRecordingScreen({super.key});

  @override
  State<BackgroundRecordingScreen> createState() =>
      _BackgroundRecordingScreenState();
}

class _BackgroundRecordingScreenState extends State<BackgroundRecordingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _stopRecording() async {
    final audioSvc = AudioRecordingService();
    if (audioSvc.isRecording) {
      await audioSvc.stopRecording();
    }

    final camSvc = CameraService();
    if (camSvc.isRecordingVideo) {
      await camSvc.stopVideoRecording();
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Recording Saved Securely"),
            backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // A modal or full screen to show recording is active
    return WillPopScope(
      onWillPop: () async =>
          false, // Prevent back button closing it accidentally
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Background Capture Active',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Audio and/or Video is currently being recorded.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 60),
              ElevatedButton.icon(
                onPressed: _stopRecording,
                icon: const Icon(Icons.stop, color: Colors.white),
                label: const Text('STOP RECORDING',
                    style: TextStyle(color: Colors.white, letterSpacing: 1.2)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: 10,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
