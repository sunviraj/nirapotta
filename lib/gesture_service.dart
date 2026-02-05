import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'data/sensor_repository.dart';
import 'data/sensor_reading_model.dart';

enum GestureType {
  SHAKE,
  IMPACT,
  UNKNOWN,
}

/// A class that listens to accelerometer events and detects specific gestures.
class GestureService {
  /// The threshold for detecting a shake.
  double shakeThreshold;

  /// The threshold for detecting a high-G impact.
  double impactThreshold;

  /// Callback when a gesture is detected.
  final Function(GestureType) onGestureDetected;

  /// Subscription to the accelerometer stream.
  StreamSubscription<UserAccelerometerEvent>? _streamSubscription;

  /// Timestamp of the last detected gesture to prevent multiple triggers.
  int _lastGestureTimestamp = 0;

  /// Minimum time between gestures in milliseconds.
  static const int _gestureDebounceDuration = 2000;

  GestureService({
    required this.onGestureDetected,
    this.shakeThreshold = 15.0,
    this.impactThreshold = 45.0, // High G-force for impact
  });

  /// Starts listening to accelerometer events.
  void startListening() {
    // We use UserAccelerometerEvent which excludes gravity to detect shakes better.
    // For fall detection (impact), sometimes raw AccelerometerEvent is better,
    // but for "Forceful Push" or "Hard Impact" user accel implies sudden stop.
    _streamSubscription =
        userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      double magnitude =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      _analyzeGesture(magnitude);

      // Log to "Brain Memory"
      SensorDataRepository().addReading(SensorReading(
        timestamp: DateTime.now(),
        x: event.x,
        y: event.y,
        z: event.z,
      ));
    });
  }

  void _analyzeGesture(double magnitude) {
    int now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastGestureTimestamp < _gestureDebounceDuration) return;

    if (magnitude > impactThreshold) {
      _lastGestureTimestamp = now;
      onGestureDetected(GestureType.IMPACT);
    } else if (magnitude > shakeThreshold) {
      _lastGestureTimestamp = now;
      onGestureDetected(GestureType.SHAKE);
    }
  }

  /// Stops listening to accelerometer events.
  void stopListening() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }
}
