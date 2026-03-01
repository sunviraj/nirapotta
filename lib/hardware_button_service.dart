import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'action_dispatcher.dart';

class HardwareButtonService {
  static final HardwareButtonService _instance =
      HardwareButtonService._internal();
  factory HardwareButtonService() => _instance;
  HardwareButtonService._internal();

  static const platform =
      MethodChannel('com.example.shake_alert_app/hardware_buttons');

  void initialize() {
    // Listen for Power Button Events from Native Android (Screen On/Off pulses)
    platform.setMethodCallHandler((call) async {
      if (call.method == 'power_button_double_click') {
        debugPrint('Double Power Click Detected');
        EmergencyActionDispatcher.dispatch(
            'double_power', 'Panic Button: Double Power Press');
      } else if (call.method == 'power_button_triple_click') {
        debugPrint('Triple Power Click Detected');
        EmergencyActionDispatcher.dispatch(
            'triple_power', 'Panic Button: Triple Power Press');
      } else if (call.method == 'volume_button_triple_click') {
        debugPrint('Triple Volume Click Detected');
        EmergencyActionDispatcher.dispatch(
            'triple_volume', 'Panic Button: Triple Volume Press');
      }
    });
  }
}
