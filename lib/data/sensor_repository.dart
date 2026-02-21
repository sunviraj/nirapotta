import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'dart:collection';
import 'sensor_reading_model.dart'; // We will create this next

/// The "Brain's Memory".
/// Stores the last N seconds of sensor data.
class SensorDataRepository {
  // Singleton pattern to ensure one memory source
  static final SensorDataRepository _instance =
      SensorDataRepository._internal();
  factory SensorDataRepository() => _instance;
  SensorDataRepository._internal();

  /// Circular buffer to hold sensor readings.
  /// Assuming 50Hz sample rate (50 readings/sec).
  /// 10 seconds = 500 readings.
  final int _maxBufferSize = 500;
  final Queue<SensorReading> _buffer = Queue<SensorReading>();

  /// Last known values for Zero-Order Hold (ZOH)
  double _lastX = 0.0;
  double _lastY = 0.0;
  double _lastZ = 0.0;
  double _lastDb = 0.0;

  /// The reason for the last triggered alert (for labeling)
  String? lastTriggerReason;

  /// Adds a new reading to the memory.
  /// Uses Zero-Order Hold to align disparate sensor streams.
  void addReading(SensorReading reading) {
    // Update last known values based on what's in this reading
    if (reading.x != 0 || reading.y != 0 || reading.z != 0) {
      _lastX = reading.x;
      _lastY = reading.y;
      _lastZ = reading.z;
    }
    if (reading.dbLevel != null) {
      _lastDb = reading.dbLevel!;
    }

    // Create a "Complete" reading combining latest updates + last known states
    final completeReading = SensorReading(
      timestamp: reading.timestamp,
      x: _lastX,
      y: _lastY,
      z: _lastZ,
      dbLevel: _lastDb,
    );

    if (_buffer.length >= _maxBufferSize) {
      _buffer.removeFirst(); // Remove oldest
    }
    _buffer.addLast(completeReading);
  }

  /// Returns the entire buffer as a list for the AI to process.
  List<SensorReading> getRecentData() {
    return _buffer.toList();
  }

  /// Clears memory (e.g., after processing an alert).
  void clear() {
    _buffer.clear();
    lastTriggerReason = null;
    // Optional: Reset last values? Or keep them contextually?
    // _lastX = 0; _lastY = 0; _lastZ = 0; _lastDb = 0;
  }

  /// Returns the buffer as a CSV string.
  String getCSVData() {
    StringBuffer sb = StringBuffer();
    sb.writeln('Timestamp,Acc_X,Acc_Y,Acc_Z,DB_Level'); // Header
    for (var reading in _buffer) {
      sb.writeln(reading.toCSV());
    }
    return sb.toString();
  }

  /// Saves the current buffer to a CSV file in the public Downloads directory.
  /// Returns the file path.
  Future<String?> saveLogsToFile() async {
    try {
      // Use the external public Downloads directory
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final String timestamp =
          DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String safeReason =
          (lastTriggerReason ?? 'MANUAL').replaceAll(' ', '_').toUpperCase();
      final String fileName = 'sensor_logs_${safeReason}_$timestamp.csv';
      final File file = File('${directory.path}/$fileName');

      String csvData = getCSVData();
      await file.writeAsString(csvData);

      debugPrint("Logs saved to: ${file.path}");
      return file.path;
    } catch (e) {
      debugPrint("Error saving logs: $e");
      return null;
    }
  }
}
