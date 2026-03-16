import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../db/database_helper.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const List<String> _hadiths = [
    'خيركم من تعلّم القرآن وعلّمه — رواه البخاري',
    'اقرأوا القرآن فإنه يأتي يوم القيامة شفيعاً لأصحابه — رواه مسلم',
    'الماهر بالقرآن مع السفرة الكرام البررة — رواه البخاري',
    'من قرأ حرفاً من كتاب الله فله به حسنة والحسنة بعشر أمثالها — رواه الترمذي',
    'إن الله يرفع بهذا الكتاب أقواماً ويضع به آخرين — رواه مسلم',
    'أهل القرآن هم أهل الله وخاصته — رواه النسائي',
    'لا حسد إلا في اثنتين: رجل آتاه الله القرآن فهو يقوم به آناء الليل وآناء النهار — رواه البخاري',
    'تعاهدوا هذا القرآن فوالذي نفسي بيده لهو أشد تفصياً من الإبل في عقلها — رواه البخاري',
    'من قرأ القرآن وعمل بما فيه ألبس والداه تاجاً يوم القيامة — رواه أبو داود',
    'اقرأ القرآن في كل شهر — رواه البخاري',
  ];

  Future<void> init() async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(initSettings);
    } catch (e) {}
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required bool enabled,
  }) async {}

  Future<void> showSmartReminder() async {
    try {
      final task = await DatabaseHelper.instance.getTodayTask();
      String title = 'وردي 📅';
      String body;

      if (task == null || task.taskText.trim().isEmpty) {
        // No task — show a Hadith
        final idx = DateTime.now().day % _hadiths.length;
        body = _hadiths[idx];
        title = '📖 حديث اليوم';
      } else if (task.status != 1) {
        body = 'لا تنسَ وردك اليوم: ${task.taskText} ⏰';
      } else {
        return; // Task done — no notification
      }

      const androidDetails = AndroidNotificationDetails(
        'yawmi_smart', 'Smart Reminder',
        channelDescription: 'Context-aware reminder',
        importance: Importance.high,
        priority: Priority.high,
      );
      await _plugin.show(
        1, title, body,
        const NotificationDetails(android: androidDetails),
      );
    } catch (e) {}
  }

  Future<void> cancelAll() async {
    try { await _plugin.cancelAll(); } catch (e) {}
  }
}
