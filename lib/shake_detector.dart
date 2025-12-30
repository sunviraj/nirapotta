import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

/// A class that listens to accelerometer events and detects shakes.
class ShakeDetector {
  /// The threshold for detecting a shake.
  /// Standard gravity is ~9.8 m/s^2.
  /// A strong shake will significantly exceed this.
  double threshold;

  /// Callback when a shake is detected.
  final VoidCallback onShake;

  /// Subscription to the accelerometer stream.
  StreamSubscription<UserAccelerometerEvent>? _streamSubscription;

  /// Timestamp of the last detected shake to prevent multiple triggers.
  int _lastShakeTimestamp = 0;

  /// Minimum time between shakes in milliseconds.
  static const int _shakeDebounceDuration = 2000;

  ShakeDetector({
    required this.onShake,
    this.threshold = 15.0, // Default threshold
  });

  /// Starts listening to accelerometer events.
  void startListening() {
    _streamSubscription = userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      // Calculate the magnitude of the acceleration vector.
      // We use UserAccelerometerEvent which excludes gravity.
      double acceleration = sqrt(
        event.x * event.x +
        event.y * event.y +
        event.z * event.z
      );

      if (acceleration > threshold) {
        int now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastShakeTimestamp > _shakeDebounceDuration) {
          _lastShakeTimestamp = now;
          onShake();
        }
      }
    });
  }

  /// Stops listening to accelerometer events.
  void stopListening() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }

  /// Updates the sensitivity threshold.
  void setThreshold(double newThreshold) {
    threshold = newThreshold;
  }
}

typedef VoidCallback = void Function();
