import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/sensor_repository.dart';
import '../data/sensor_reading_model.dart'; // Import model
import '../widgets/glass_container.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  late List<SensorReading> _logs;
  String? _csvData;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    setState(() {
      _logs = SensorDataRepository().getRecentData();
      _csvData = SensorDataRepository().getCSVData();
    });
  }

  void _copyToClipboard() {
    if (_csvData != null) {
      Clipboard.setData(ClipboardData(text: _csvData!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV Data copied to clipboard!')),
      );
    }
  }

  Future<void> _saveLogsToFile() async {
    String? path = await SensorDataRepository().saveLogsToFile();
    if (!mounted) return;

    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logs saved to: $path'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save logs.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sensor Logs (AI Data)',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyToClipboard,
          ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: _saveLogsToFile, // New Save Action
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
        child: Column(
          children: [
            // Info Header
            GlassContainer(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              opacity: 0.1,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Capturing last ${_logs.length} readings. Copy this data to train your AI model.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  // Show newest first
                  final reading = _logs[_logs.length - 1 - index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      'x:${reading.x.toStringAsFixed(2)} y:${reading.y.toStringAsFixed(2)} z:${reading.z.toStringAsFixed(2)}',
                      style: GoogleFonts.notoSansMono(color: Colors.white),
                    ),
                    trailing: Text(
                      '${reading.dbLevel?.toStringAsFixed(1) ?? "--"} dB',
                      style: TextStyle(
                        color: (reading.dbLevel ?? 0) > 80
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      DateTime.fromMillisecondsSinceEpoch(
                              reading.timestamp.millisecondsSinceEpoch)
                          .toString()
                          .split(' ')[1], // Show time only
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
