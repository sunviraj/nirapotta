import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'audio_recording_service.dart';
import 'camera_service.dart';
import 'notification_service.dart';
import 'main.dart';
import 'screens/background_recording_screen.dart';

class EmergencyActionDispatcher {
  /// Dispatches the customized actions tied to a specific trigger event
  static Future<void> dispatch(String triggerKey, String reason) async {
    final prefs = await SharedPreferences.getInstance();

    // Load the user's customized actions, or use safe sensible defaults if not yet set
    List<String> actions =
        prefs.getStringList('trigger_$triggerKey') ?? _getDefault(triggerKey);

    debugPrint('Dispatching Trigger: $triggerKey with actions: $actions');

    if (actions.contains('sms')) {
      await NotificationService().sendEmergencyAlert(reason);
    }

    if (actions.contains('audio')) {
      final audioSvc = AudioRecordingService();
      // Only start if not already recording
      if (!audioSvc.isRecording) {
        await audioSvc.startRecording();
      }
    }

    if (actions.contains('video')) {
      final camSvc = CameraService();
      // Only start if not already recording
      if (!camSvc.isRecordingVideo) {
        await camSvc.startVideoRecording();
      }
    }

    if (triggerKey == 'triple_volume') {
      if (navigatorKey.currentContext != null) {
        Navigator.of(navigatorKey.currentContext!).push(
          MaterialPageRoute(builder: (_) => const BackgroundRecordingScreen()),
        );
      }
    }
  }

  static List<String> _getDefault(String key) {
    switch (key) {
      case 'shake':
        return ['sms'];
      case 'loud_noise':
        return ['sms'];
      case 'double_power':
        return ['audio'];
      case 'triple_power':
        return ['video'];
      case 'triple_volume':
        return ['video', 'audio'];
      default:
        return [];
    }
  }
}
