import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../db/database_helper.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(initSettings);
      _initialized = true;
    } catch (e) {
      _initialized = true;
    }
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required bool enabled,
  }) async {
    try {
      await _plugin.cancelAll();
      if (!enabled) return;
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
      const androidDetails = AndroidNotificationDetails(
        'yawmi_daily', 'Daily Reminder',
        channelDescription: 'Daily task reminder',
        importance: Importance.high,
        priority: Priority.high,
      );
      await _plugin.zonedSchedule(
        0,
        'يومي',
        'تذكير مهمة اليوم',
        scheduled,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {}
  }

  Future<void> showSmartReminder() async {
    try {
      final task = await DatabaseHelper.instance.getTodayTask();
      String body;
      if (task == null || task.taskText.trim().isEmpty) {
        body = 'لم تسجّل مهمة لهذا اليوم بعد 📝';
      } else if (task.status != 1) {
        body = 'لا تنسَ مهمتك: ${task.taskText} ⏰';
      } else {
        return;
      }
      const androidDetails = AndroidNotificationDetails(
        'yawmi_smart', 'Smart Reminder',
        channelDescription: 'Context-aware reminder',
        importance: Importance.high,
        priority: Priority.high,
      );
      await _plugin.show(
        1,
        'يومي 📅',
        body,
        const NotificationDetails(android: androidDetails),
      );
    } catch (e) {}
  }

  Future<void> cancelAll() async {
    try { await _plugin.cancelAll(); } catch (e) {}
  }
}
