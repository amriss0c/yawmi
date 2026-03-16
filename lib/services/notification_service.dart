import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../db/database_helper.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _notifications.initialize(initSettings);
  }

  /// Targets ONLY today's date.
  static Future<void> checkTodayTaskAndNotify() async {
    final now = DateTime.now();
    // Generates the key for today ONLY (e.g., "2026-03-07")
    final todayKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    // Fetch specifically the task for today from SQLite
    final task = await DatabaseHelper.instance.getTask(todayKey);

    // LOGIC: 
    // 1. Task must exist for today.
    // 2. Task text must not be empty.
    // 3. Status must be 0 (Uncompleted).
    if (task != null && task.taskText.isNotEmpty && task.status == 0) {
      await _showNotification(
        id: 777, // Unique ID for today's reminder
        title: "مهمة اليوم لم تكتمل",
        body: "تذكير: ${task.taskText}",
      );
    }
  }

  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'today_reminder_channel',
        'Today\'s Task Reminder',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      ),
    );
    await _notifications.show(id, title, body, details);
  }
}