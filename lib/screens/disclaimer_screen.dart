import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'permission_screen.dart';
import '../widgets/glass_container.dart';

class DisclaimerScreen extends StatefulWidget {
  const DisclaimerScreen({super.key});

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  bool _hasScrolledToBottom = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Important Disclaimer'),
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
            child: Column(
              children: [
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (!_hasScrolledToBottom &&
                          scrollInfo.metrics.pixels >=
                              scrollInfo.metrics.maxScrollExtent - 20) {
                        setState(() {
                          _hasScrolledToBottom = true;
                        });
                      }
                      return true;
                    },
                    child: SingleChildScrollView(
                      child: GlassContainer(
                        padding: const EdgeInsets.all(20),
                        opacity: 0.05,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Terms of Use & Safety Notice',
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildSection(
                              title: 'Experimental Stage',
                              content:
                                  'This application (Nirapotta V3) is currently undergoing development and testing for a university project. It is an experimental prototype and is NOT a guaranteed replacement for contacting professional emergency services.',
                            ),
                            _buildSection(
                              title: 'No Guarantees',
                              content:
                                  'By using this app, you acknowledge that the autonomous detection algorithms (falls, impacts, shouts) may produce false positives or fail to detect an actual emergency entirely. Reliance on this app is at your own risk.',
                            ),
                            _buildSection(
                              title: 'Data Collection & Privacy',
                              content:
                                  'To improve the AI algorithms, this app collects sensor telemetry (accelerometer data, microphone volume spikes) and visual evidence (photos during an alert). This data is stored strictly locally on your device unless manually exported by you. No actual audio recordings are saved.',
                            ),
                            _buildSection(
                              title: 'Emergency Protocol',
                              content:
                                  'In the event of a true emergency, YOUR FIRST ACTION should always be to dial local emergency services directly if you are able to do so.',
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              '(Scroll to the bottom to accept)',
                              style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white30,
                                  fontSize: 12),
                              textAlign: TextAlign.center,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasScrolledToBottom
                          ? Colors.redAccent
                          : Colors.grey[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _hasScrolledToBottom
                        ? () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (_) => const PermissionScreen()),
                            );
                          }
                        : null,
                    child: Text(
                      'I UNDERSTAND AND ACCEPT',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _hasScrolledToBottom
                            ? Colors.white
                            : Colors.white54,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
