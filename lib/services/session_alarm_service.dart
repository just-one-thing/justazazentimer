import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:wakelock_plus/wakelock_plus.dart';

abstract class SessionAlarmService {
  Future<void> initialize();
  Future<void> scheduleSessionEndAlarm({required Duration duration});
  Future<void> cancelSessionEndAlarm();
  Future<void> setScreenWakelock(bool enable);
}

class AndroidSessionAlarmService implements SessionAlarmService {
  AndroidSessionAlarmService({
    FlutterLocalNotificationsPlugin? notificationsPlugin,
  }) : _plugin = notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  static const int sessionNotificationId = 108;
  static const String channelId = 'zazen_session_end';
  static const String channelName = 'Zazen Session Completion';
  static const String channelDesc =
      'Alerts with Tibetan bells and wakes screen when meditation ends';

  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
    } catch (_) {
      // Timezone data already initialized or fallback
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidSettings,
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
    );

    try {
      await _plugin.initialize(settings: initSettings);

      // Create high-priority notification channel with custom bell sound
      final androidNotificationChannel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDesc,
        importance: Importance.max,
        sound: const RawResourceAndroidNotificationSound('tibetan_bell_3x'),
        playSound: true,
        enableVibration: true,
        bypassDnd: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );

      final androidImplementation =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(
          androidNotificationChannel,
        );
        // Request permissions for Android 13+
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      }
      _initialized = true;
    } catch (e) {
      debugPrint('Alarm notification initialization fallback: $e');
    }
  }

  @override
  Future<void> scheduleSessionEndAlarm({required Duration duration}) async {
    try {
      await initialize();
      final scheduledDate = tz.TZDateTime.now(tz.local).add(duration);

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('tibetan_bell_3x'),
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        visibility: NotificationVisibility.public,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _plugin.zonedSchedule(
        id: sessionNotificationId,
        title: 'Zazen Complete',
        body: 'Your meditation session has ended.',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Failed to schedule session end alarm: $e');
    }
  }

  @override
  Future<void> cancelSessionEndAlarm() async {
    try {
      await _plugin.cancel(id: sessionNotificationId);
    } catch (_) {}
  }

  @override
  Future<void> setScreenWakelock(bool enable) async {
    try {
      if (enable) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {
      // Wakelock gracefully ignores unsupported platforms
    }
  }
}

class MockSessionAlarmService implements SessionAlarmService {
  bool isInitialized = false;
  Duration? scheduledDuration;
  bool wakelockActive = false;
  int cancelCount = 0;

  @override
  Future<void> initialize() async {
    isInitialized = true;
  }

  @override
  Future<void> scheduleSessionEndAlarm({required Duration duration}) async {
    scheduledDuration = duration;
  }

  @override
  Future<void> cancelSessionEndAlarm() async {
    cancelCount++;
    scheduledDuration = null;
  }

  @override
  Future<void> setScreenWakelock(bool enable) async {
    wakelockActive = enable;
  }
}
