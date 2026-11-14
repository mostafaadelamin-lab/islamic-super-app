import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

/// Where the phone stands on what the adhan needs to ring on time with the app
/// closed. Used by the first-run setup and Settings > "Permissions and background".
///
/// What is asked, and why (store review: every prompt says what it is for):
/// * location "while using the app" (never "always") for prayer times;
/// * notifications, for the adhan and reminders;
/// * Android 12+: "Alarms & reminders" (exact alarms), so the adhan is on the minute;
/// * Android: no battery optimization for the app, so the system does not hold the
///   alarms back. The app opens the system list (it does not hold the
///   REQUEST_IGNORE_BATTERY_OPTIMIZATIONS permission, which Google Play restricts).
///
/// Not asked: "display over other apps" and full-screen intents. The adhan is an
/// exact alarm that starts a media-playback foreground service with a notification
/// (android/.../AdhanService.kt), which needs neither.
abstract class DeviceSetup {
  /// Android only: exact alarms and battery optimization exist there.
  bool get isAndroid;

  bool get isIos;

  Future<bool> locationAllowed();
  Future<bool> notificationsAllowed();

  /// Android 12+: the "Alarms & reminders" switch. Always true elsewhere.
  Future<bool> exactAlarmsAllowed();

  /// Android: the app is exempt from battery optimization. Always true elsewhere.
  Future<bool> batteryUnrestricted();

  Future<void> openExactAlarmSettings();
  Future<void> openBatterySettings();
  Future<void> openAppSettings();
  Future<void> openNotificationSettings();
}

class PlatformDeviceSetup implements DeviceSetup {
  PlatformDeviceSetup();

  static const _channel = MethodChannel('org.rattil.app/adhan');

  @override
  bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  bool get isIos => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<bool> _ask(String method, {bool fallback = true}) async {
    try {
      return await _channel.invokeMethod<bool>(method) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  @override
  Future<bool> locationAllowed() async {
    try {
      final p = await Geolocator.checkPermission();
      return p == LocationPermission.whileInUse || p == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> notificationsAllowed() async {
    if (isAndroid) return _ask('notificationsEnabled', fallback: false);
    if (isIos) {
      try {
        final ios = FlutterLocalNotificationsPlugin()
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final o = await ios?.checkPermissions();
        return o?.isEnabled ?? false;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  @override
  Future<bool> exactAlarmsAllowed() async => isAndroid ? _ask('canScheduleExact') : true;

  @override
  Future<bool> batteryUnrestricted() async => isAndroid ? _ask('ignoringBatteryOptimizations') : true;

  @override
  Future<void> openExactAlarmSettings() => _ask('openExactAlarmSettings');

  @override
  Future<void> openBatterySettings() => _ask('openBatterySettings');

  @override
  Future<void> openAppSettings() async {
    if (isAndroid) {
      await _ask('openAppSettings');
    } else {
      try {
        await Geolocator.openAppSettings();
      } catch (_) {}
    }
  }

  @override
  Future<void> openNotificationSettings() async {
    if (isAndroid) {
      await _ask('openNotificationSettings');
    } else {
      await openAppSettings();
    }
  }
}
