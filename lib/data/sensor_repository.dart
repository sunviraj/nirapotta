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

  /// Adds a new reading to the memory.
  void addReading(SensorReading reading) {
    if (_buffer.length >= _maxBufferSize) {
      _buffer.removeFirst(); // Remove oldest
    }
    _buffer.addLast(reading);

    // In debug mode, verify we are recording
    // if (kDebugMode && _buffer.length % 100 == 0) {
    //   print("Brain Memory: ${_buffer.length} readings stored.");
    // }
  }

  /// Returns the entire buffer as a list for the AI to process.
  List<SensorReading> getRecentData() {
    return _buffer.toList();
  }

  /// Clears memory (e.g., after processing an alert).
  void clear() {
    _buffer.clear();
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
}
