import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart'; // Using gal for gallery saving
import 'package:intl/intl.dart';

class CameraService {
  // Singleton pattern
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  CameraController? _controller;
  bool _isInitialized = false;

  /// Initializes the camera in the background.
  /// Should be called when the app starts.
  Future<void> initialize() async {
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
        enableAudio: false, // No audio needed for photo
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
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

      // Rename the file to include the reason
      final String timestamp =
          DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String safeReason = reason.replaceAll(' ', '_').toUpperCase();
      final String dir = File(image.path).parent.path;
      final String newPath = '$dir/${safeReason}_$timestamp.jpg';

      await File(image.path).rename(newPath);

      // Move to permanent storage (Gallery) using the gal package
      await Gal.putImage(newPath, album: 'Nirapotta');
      debugPrint('Evidence photo saved to Gallery: $newPath');

      // Dispose camera after taking photo to fulfill requirement (inactive by default)
      dispose();

      return newPath;
    } catch (e) {
      debugPrint('Error taking picture: $e');
      dispose();
      return null;
    }
  }

  /// Disposes the camera controller.
  void dispose() {
    _controller?.dispose();
    _isInitialized = false;
  }
}
