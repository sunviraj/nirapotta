import 'dart:async';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'data/sensor_repository.dart';
import 'data/sensor_reading_model.dart';

class SoundService {
  /// Callback when a loud noise is detected.
  final VoidCallback onLoudNoiseDetected;

  /// Threshold in Decibels (dB).
  /// Normal conversation ~60dB, Scream/Loud noise ~85-90dB.
  double dbThreshold;

  NoiseMeter? _noiseMeter;
  StreamSubscription<NoiseReading>? _noiseSubscription;
  bool _isListening = false;
  int _listenStartTime = 0; // Timestamp when listening started

  /// Debounce to prevent multiple triggers
  int _lastTriggerTimestamp = 0;
  static const int _triggerDebounceDuration = 2000;

  SoundService({
    required this.onLoudNoiseDetected,
    this.dbThreshold = 85.0,
  });

  Future<void> startListening() async {
    if (_isListening) return;

    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      debugPrint('Microphone permission denied');
      return;
    }

    try {
      _noiseMeter = NoiseMeter();
      _noiseSubscription = _noiseMeter?.noise.listen(
        (NoiseReading reading) {
          _analyzeSound(reading);
        },
        onError: (Object error) {
          debugPrint('NoiseMeter Error: $error');
          _isListening = false;
        },
      );
      _isListening = true;
      _listenStartTime =
          DateTime.now().millisecondsSinceEpoch; // Record start time for warmup
    } catch (e) {
      debugPrint('Error starting NoiseMeter: $e');
    }
  }

  void _analyzeSound(NoiseReading reading) {
    int now = DateTime.now().millisecondsSinceEpoch;

    // Ignore sound spikes during the first 1 second of initialization (Warm-up period)
    if (now - _listenStartTime < 1000) return;

    // Log to "Brain Memory"
    SensorDataRepository().addReading(SensorReading(
      timestamp: DateTime.now(),
      x: 0,
      y: 0,
      z: 0,
      dbLevel: reading.maxDecibel,
    ));

    if (reading.maxDecibel > dbThreshold) {
      int now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastTriggerTimestamp > _triggerDebounceDuration) {
        _lastTriggerTimestamp = now;
        debugPrint('Loud noise detected: ${reading.maxDecibel} dB');
        onLoudNoiseDetected();
      }
    }
  }

  void stopListening() {
    _noiseSubscription?.cancel();
    _noiseSubscription = null;
    _isListening = false;
  }

  bool get isListening => _isListening;
}
