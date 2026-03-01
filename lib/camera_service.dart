import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class CameraService {
  // Singleton pattern
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  CameraController? _controller;
  bool _isInitialized = false;
  bool _isRecordingVideo = false;

  CameraController? get controller => _controller;
  bool get isRecordingVideo => _isRecordingVideo;
  bool get isInitialized => _isInitialized;

  /// Initializes the camera.
  /// Should be called when the app starts.
  Future<void> initialize({bool enableAudio = true}) async {
    if (_isInitialized) return;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No cameras found');
        return;
      }

      // Use the back camera
      final firstCamera = cameras.first;

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.medium, // Medium resolution is enough for evidence
        enableAudio: enableAudio, // Changed to support video recording
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      // Ensure flash is NEVER used for background capturing
      await _controller!.setFlashMode(FlashMode.off);
      _isInitialized = true;
      debugPrint('Camera initialized');
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  /// Takes a picture and saves it to local storage.
  /// Returns the file path of the saved image.
  Future<String?> takeEvidencePhoto(String reason) async {
    if (!_isInitialized ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      debugPrint('Camera not initialized, attempting to initialize...');
      await initialize();
      // Small delay to allow camera sensor and flash to fully initialize
      await Future.delayed(const Duration(milliseconds: 500));
      if (!_isInitialized) return null;
    }

    try {
      if (_controller!.value.isTakingPicture) {
        debugPrint('Camera is already taking a picture');
        return null; // Prevent overlapping captures
      }

      final XFile image = await _controller!.takePicture();

      // Move to secure evidence directory
      final Directory extDir = await getApplicationDocumentsDirectory();
      final String dirPath = '${extDir.path}/evidence';
      await Directory(dirPath).create(recursive: true);

      final String timestamp =
          DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String newPath = '$dirPath/IMAGE_$timestamp.jpg';

      await File(image.path).rename(newPath);

      debugPrint('Evidence photo saved to Secure Directory: $newPath');

      // Dispose camera after taking photo to fulfill requirement (inactive by default)
      dispose();

      return newPath;
    } catch (e) {
      debugPrint('Error taking picture: $e');
      dispose();
      return null;
    }
  }

  Future<void> startVideoRecording() async {
    if (!_isInitialized ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      await initialize(enableAudio: true);
      // Small delay to allow camera sensor to initialize
      await Future.delayed(const Duration(milliseconds: 500));
      if (!_isInitialized) return;
    }

    if (_controller!.value.isRecordingVideo) {
      debugPrint('Camera is already recording video');
      return;
    }

    try {
      await _controller!.startVideoRecording();
      _isRecordingVideo = true;
      debugPrint('Started background video recording');
    } catch (e) {
      debugPrint('Error starting video recording: $e');
    }
  }

  Future<String?> stopVideoRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) {
      return null;
    }

    try {
      final XFile video = await _controller!.stopVideoRecording();
      _isRecordingVideo = false;

      // Move to secure evidence directory
      final Directory extDir = await getApplicationDocumentsDirectory();
      final String dirPath = '${extDir.path}/evidence';
      await Directory(dirPath).create(recursive: true);

      final String timestamp =
          DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String newPath = '$dirPath/VIDEO_$timestamp.mp4';

      await File(video.path).rename(newPath);
      debugPrint('Video evidence saved to Secure Directory: $newPath');
      dispose();
      return newPath;
    } catch (e) {
      debugPrint('Error stopping video recording: $e');
      dispose();
      return null;
    }
  }

  /// Disposes the camera controller.
  void dispose() {
    _controller?.dispose();
    _isInitialized = false;
    _isRecordingVideo = false;
  }
}
