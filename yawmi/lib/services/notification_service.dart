import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../db/database_helper.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const int _quranNotifId   = 42;
  static const int _fastingMorning = 101;
  static const int _fastingMidday  = 102;
  static const int _fastingEvening = 103;

  // ── QURAN HADITHS ────────────────────────────────────────────────────
  static const List<Map<String, String>> quranHadiths = [
    {'text': 'خيركم من تعلّم القرآن وعلّمه', 'source': 'رواه البخاري'},
    {'text': 'اقرأوا القرآن فإنه يأتي يوم القيامة شفيعاً لأصحابه', 'source': 'رواه مسلم'},
    {'text': 'الماهر بالقرآن مع السفرة الكرام البررة', 'source': 'رواه البخاري'},
    {'text': 'من قرأ حرفاً من كتاب الله فله به حسنة والحسنة بعشر أمثالها', 'source': 'رواه الترمذي'},
    {'text': 'إن الله يرفع بهذا الكتاب أقواماً ويضع به آخرين', 'source': 'رواه مسلم'},
    {'text': 'أهل القرآن هم أهل الله وخاصته', 'source': 'رواه النسائي'},
    {'text': 'لا حسد إلا في اثنتين: رجل آتاه الله القرآن فهو يقوم به آناء الليل وآناء النهار', 'source': 'رواه البخاري'},
    {'text': 'تعاهدوا هذا القرآن فوالذي نفسي بيده لهو أشد تفصياً من الإبل في عقلها', 'source': 'رواه البخاري'},
    {'text': 'من قرأ القرآن وعمل بما فيه ألبس والداه تاجاً يوم القيامة', 'source': 'رواه أبو داود'},
    {'text': 'اقرأ القرآن في كل شهر', 'source': 'رواه البخاري'},
  ];

  // ── FASTING HADITHS: Monday & Thursday ───────────────────────────────
  static const List<Map<String, String>> mondayThursdayHadiths = [
    {
      'text': 'تُعرض الأعمال يوم الاثنين والخميس، فأحب أن يُعرض عملي وأنا صائم',
      'source': 'رواه الترمذي',
    },
    {
      'text': 'إن الأعمال تُعرض كل اثنين وخميس فيغفر الله لكل مسلم لا يشرك به شيئاً',
      'source': 'رواه مسلم',
    },
    {
      'text': 'كان النبي ﷺ يتحرى صيام الاثنين والخميس',
      'source': 'رواه الترمذي',
    },
  ];

  // ── FASTING HADITHS: Ayyam al-Beed ──────────────────────────────────
  static const List<Map<String, String>> ayyamBeedHadiths = [
    {
      'text': 'صيام ثلاثة أيام من كل شهر صيام الدهر كله',
      'source': 'رواه البخاري',
    },
    {
      'text': 'يا أبا ذر إذا صمت من الشهر ثلاثة أيام فصم ثلاث عشرة وأربع عشرة وخمس عشرة',
      'source': 'رواه الترمذي',
    },
    {
      'text': 'كان رسول الله ﷺ لا يُفطر أيام البيض في سفر ولا حضر',
      'source': 'رواه النسائي',
    },
  ];

  // ── INIT ─────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();
      try { tz.setLocalLocation(tz.getLocation('Asia/Riyadh')); }
      catch (_) { tz.setLocalLocation(tz.getLocation('UTC')); }

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(const InitializationSettings(android: androidSettings));
      await _requestPermission();
      _initialized = true;
      debugPrint('NotificationService: initialized OK');
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  Future<void> _requestPermission() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) await android.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Permission request error: $e');
    }
  }

  // ── QURAN DAILY REMINDER ─────────────────────────────────────────────
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required bool enabled,
  }) async {
    if (!_initialized) await init();
    await _plugin.cancel(_quranNotifId);
    if (!enabled) return;
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));

      const androidDetails = AndroidNotificationDetails(
        'wirdi_daily', 'تذكير يومي',
        channelDescription: 'تذكير يومي بالورد القرآني',
        importance: Importance.high, priority: Priority.high,
        playSound: true, enableVibration: true,
      );
      await _plugin.zonedSchedule(
        _quranNotifId, 'وردي 📖', 'حان وقت وردك اليومي',
        scheduled,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('Quran reminder scheduled at $hour:$minute');
    } catch (e) {
      debugPrint('scheduleDailyReminder error: $e');
    }
  }

  // ── FASTING REMINDERS ────────────────────────────────────────────────
  // Determines if a given date is a fasting day (Monday/Thursday/Ayyam al-Beed)
  static Map<String, dynamic> getFastingInfo(DateTime date) {
    final weekday = date.weekday; // 1=Mon, 4=Thu
    final hijri = HijriCalendar.fromDate(date);
    final hijriDay = hijri.hDay;

    final isMondayThursday = weekday == 1 || weekday == 4;
    final isAyyamBeed = hijriDay == 13 || hijriDay == 14 || hijriDay == 15;

    return {
      'isFastingDay': isMondayThursday || isAyyamBeed,
      'isMondayThursday': isMondayThursday,
      'isAyyamBeed': isAyyamBeed,
      'weekday': weekday,
      'hijriDay': hijriDay,
    };
  }

  // Build notification title and body for a fasting day
  static Map<String, String> _buildFastingContent(DateTime fastingDate, int reminderIndex) {
    final info = getFastingInfo(fastingDate);
    final isMon = fastingDate.weekday == 1;
    final isThu = fastingDate.weekday == 4;
    final isAyyam = info['isAyyamBeed'] as bool;
    final isMT = info['isMondayThursday'] as bool;

    String title;
    String body;

    // Build title
    if (isMT && isAyyam) {
      title = isMon ? '🌙 غداً الاثنين وأيام البيض'
                    : '🌙 غداً الخميس وأيام البيض';
    } else if (isMT) {
      title = isMon ? '🌙 غداً يوم الاثنين' : '🌙 غداً يوم الخميس';
    } else {
      final hijriDay = (info['hijriDay'] as int) + 1;
      title = '🌙 غداً ${_hijriDayName(hijriDay)} من أيام البيض';
    }

    // Build body — rotate Hadiths by reminder index
    if (isMT && isAyyam) {
      // Combine both — alternate between the two lists
      final h = reminderIndex % 2 == 0
          ? mondayThursdayHadiths[reminderIndex % mondayThursdayHadiths.length]
          : ayyamBeedHadiths[reminderIndex % ayyamBeedHadiths.length];
      body = '${h['text']} — ${h['source']}';
    } else if (isMT) {
      final h = mondayThursdayHadiths[reminderIndex % mondayThursdayHadiths.length];
      body = '${h['text']} — ${h['source']}';
    } else {
      final h = ayyamBeedHadiths[reminderIndex % ayyamBeedHadiths.length];
      body = '${h['text']} — ${h['source']}';
    }

    return {'title': title, 'body': body};
  }

  static String _hijriDayName(int day) {
    const names = {13: 'اليوم الثالث عشر', 14: 'اليوم الرابع عشر', 15: 'اليوم الخامس عشر'};
    return names[day] ?? 'يوم';
  }

  /// Schedule 3 fasting reminders for the day before each fasting day.
  /// Called on app init and when settings change.
  Future<void> scheduleFastingReminders({
    required bool enabled,
    required int morningHour,   required int morningMinute,
    required int middayHour,    required int middayMinute,
    required int eveningHour,   required int eveningMinute,
  }) async {
    if (!_initialized) await init();

    // Cancel existing fasting notifications
    await _plugin.cancel(_fastingMorning);
    await _plugin.cancel(_fastingMidday);
    await _plugin.cancel(_fastingEvening);

    if (!enabled) {
      debugPrint('Fasting reminders disabled');
      return;
    }

    try {
      final now = tz.TZDateTime.now(tz.local);
      // Check next 7 days — find the soonest fasting day and schedule reminders
      // for the day before it
      for (int offset = 1; offset <= 7; offset++) {
        final candidate = now.add(Duration(days: offset));
        final candidateDate = DateTime(candidate.year, candidate.month, candidate.day);
        final info = getFastingInfo(candidateDate);

        if (info['isFastingDay'] as bool) {
          // The day BEFORE the fasting day
          final dayBefore = candidateDate.subtract(const Duration(days: 1));

          final times = [
            [morningHour,  morningMinute,  _fastingMorning,  0],
            [middayHour,   middayMinute,   _fastingMidday,   1],
            [eveningHour,  eveningMinute,  _fastingEvening,  2],
          ];

          for (final t in times) {
            final h = t[0] as int;
            final m = t[1] as int;
            final id = t[2] as int;
            final idx = t[3] as int;

            var scheduled = tz.TZDateTime(
              tz.local,
              dayBefore.year, dayBefore.month, dayBefore.day, h, m,
            );

            // Skip if this time already passed
            if (scheduled.isBefore(now)) continue;

            final content = _buildFastingContent(candidateDate, idx);
            const androidDetails = AndroidNotificationDetails(
              'wirdi_fasting', 'تذكير الصيام',
              channelDescription: 'تذكير بصيام الأيام الفاضلة',
              importance: Importance.high, priority: Priority.high,
              playSound: true, enableVibration: true,
              styleInformation: BigTextStyleInformation(''),
            );

            await _plugin.zonedSchedule(
              id,
              content['title']!,
              content['body']!,
              scheduled,
              const NotificationDetails(android: androidDetails),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
            );
            debugPrint('Fasting reminder $id scheduled: ${content['title']} at $h:$m on ${dayBefore.day}/${dayBefore.month}');
          }
          break; // Only schedule for the nearest fasting day
        }
      }
    } catch (e) {
      debugPrint('scheduleFastingReminders error: $e');
    }
  }

  // ── SMART QURAN REMINDER (on notification fire) ──────────────────────
  Future<void> showSmartReminder() async {
    if (!_initialized) await init();
    try {
      final task = await DatabaseHelper.instance.getTodayTask();
      String title; String body;
      if (task == null || task.taskText.trim().isEmpty) {
        title = '📖 حديث اليوم';
        body = quranHadiths[DateTime.now().day % quranHadiths.length]['text']!;
      } else if (task.status == 1) {
        title = '✅ أحسنت!';
        body = 'أتممت وردك اليوم: ${task.taskText.trim()} — بارك الله فيك';
      } else {
        title = '⏰ وردك اليومي';
        body = 'لا تنسَ: ${task.taskText.trim()}';
      }
      const androidDetails = AndroidNotificationDetails(
        'wirdi_smart', 'تذكير ذكي',
        channelDescription: 'تذكير مخصص بناءً على حالة الورد',
        importance: Importance.high, priority: Priority.high,
        playSound: true, enableVibration: true,
      );
      await _plugin.show(_quranNotifId + 1, title, body,
          const NotificationDetails(android: androidDetails));
    } catch (e) {
      debugPrint('showSmartReminder error: $e');
    }
  }

  Future<void> cancelAll() async {
    try { await _plugin.cancelAll(); } catch (e) {}
  }
}
