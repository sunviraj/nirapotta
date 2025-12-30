# Shake Alert App

A Flutter application that detects strong shake gestures and triggers a simulated emergency alert.

## Features
- **Real-time Shake Detection**: Uses device accelerometer.
- **Configurable Sensitivity**: Adjust the shake threshold.
- **Simulated Alert**: Fullscreen red alert, loud sound, and vibration.
- **Safety First**: Clear disclaimer that this is a simulation.

## Prerequisites
- Flutter SDK installed (run `flutter doctor` to check).
- A physical Android or iOS device (Simulators/Emulators often do not support accelerometer events properly).

## Setup Instructions

1.  Open the app.
2.  Read the safety disclaimer.
3.  Tap **START DETECTION**.
4.  Shake the device vigorously.
5.  The **Emergency Alert** screen will appear with sound and vibration.
6.  Tap **STOP ALARM** to dismiss.
7.  Adjust the **Sensitivity Slider** if it triggers too easily or is too hard to trigger.

## Troubleshooting
- **"MissingPluginException"**: Stop the app completely and run `flutter run` again after adding new dependencies.
- **No Sound**: Verify `assets/alert_sound.mp3` exists and is listed in `pubspec.yaml`.
- **No Shake Detected**: Ensure you are on a physical device. Emulators usually require specific settings to simulate shake.
