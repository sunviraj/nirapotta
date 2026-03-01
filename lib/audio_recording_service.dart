import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:intl/intl.dart';

class AudioRecordingService {
  static final AudioRecordingService _instance =
      AudioRecordingService._internal();
  factory AudioRecordingService() => _instance;
  AudioRecordingService._internal();

  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  Future<void> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final Directory extDir = await getApplicationDocumentsDirectory();
        final String dirPath = '${extDir.path}/evidence';
        await Directory(dirPath).create(recursive: true);

        final String timestamp =
            DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final String filePath = '$dirPath/AUDIO_$timestamp.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
          path: filePath,
        );

        _isRecording = true;
        debugPrint('Started recording audio to: $filePath');
      }
    } catch (e) {
      debugPrint('Error starting audio recording: $e');
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      debugPrint('Audio recording stopped. Saved to: $path');
      return path;
    } catch (e) {
      debugPrint('Error stopping audio recording: $e');
      return null;
    }
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}
