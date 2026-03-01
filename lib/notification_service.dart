import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'location_service.dart';

enum SmsStatus { sent, failed }

class BackgroundSms {
  static const MethodChannel _channel =
      MethodChannel('com.example.shake_alert_app/background_sms');

  static Future<SmsStatus> sendMessage(
      {required String phoneNumber, required String message}) async {
    try {
      final String? result = await _channel.invokeMethod('sendSms', {
        'phone': phoneNumber,
        'msg': message,
      });
      return result == "Sent" ? SmsStatus.sent : SmsStatus.failed;
    } catch (e) {
      debugPrint('Error sending SMS: $e');
      return SmsStatus.failed;
    }
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Sends an emergency SMS to all saved contacts with a specific reason and location.
  Future<void> sendEmergencyAlert(String reason) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> contacts = prefs.getStringList('emergency_contacts') ?? [];

    if (contacts.isEmpty) {
      debugPrint('Cannot send alert. No emergency contacts saved.');
      return;
    }

    if (await Permission.sms.isGranted) {
      String locationLink = await LocationService().getMapsLink();
      String message =
          "EMERGENCY ALERT: $reason.\nLocation: $locationLink.\nSent automatically via Nirapotta.";

      for (String number in contacts) {
        try {
          // To avoid sending actual SMS during heavy emulator testing we wrap this in a print
          // But this will execute on a real device
          SmsStatus result = await BackgroundSms.sendMessage(
              phoneNumber: number, message: message);

          if (result == SmsStatus.sent) {
            debugPrint('Alert Sent Successfully to $number');
          } else {
            debugPrint('Failed to send alert to $number');
          }
        } catch (e) {
          debugPrint('Error sending SMS to $number: $e');
        }
      }
    } else {
      debugPrint('SMS Permission not granted. Cannot send background alerts.');
    }
  }
}
