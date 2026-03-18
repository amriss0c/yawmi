import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/database_helper.dart';
import '../models/day_task.dart';
import '../services/notification_service.dart';
import '../services/onedrive_service.dart';
import '../services/quotes_service.dart';

enum SyncStatus { idle, syncing, success, error, notConfigured }

class TaskProvider extends ChangeNotifier {
  Map<String, DayTask> _monthTasks = {};
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  DateTime? _cachedMonth;

  bool _startOnSaturday = true;
  bool _arabicMode = true;
  bool _isDarkMode = false;
  bool _isLoading = false;

  // Quran reminder
  bool _notificationsEnabled = true;
  int _reminderHour = 18;
  int _reminderMinute = 0;

  // Fasting reminders
  bool _fastingRemindersEnabled = true;
  int _fastingMorningHour = 7;   int _fastingMorningMinute = 0;
  int _fastingMiddayHour = 12;   int _fastingMiddayMinute = 0;
  int _fastingEveningHour = 20;  int _fastingEveningMinute = 0;

  int _streakCount = 0;
  SyncStatus _syncStatus = SyncStatus.notConfigured;
  DateTime? _lastSyncTime;
  String? _signedInUser;

  // Getters
  Map<String, DayTask> get monthTasks => _monthTasks;
  DateTime get focusedMonth => _focusedMonth;
  DateTime get selectedDate => _selectedDate;
  bool get startOnSaturday => _startOnSaturday;
  bool get arabicMode => _arabicMode;
  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;
  bool get notificationsEnabled => _notificationsEnabled;
  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;
  bool get fastingRemindersEnabled => _fastingRemindersEnabled;
  int get fastingMorningHour => _fastingMorningHour;
  int get fastingMorningMinute => _fastingMorningMinute;
  int get fastingMiddayHour => _fastingMiddayHour;
  int get fastingMiddayMinute => _fastingMiddayMinute;
  int get fastingEveningHour => _fastingEveningHour;
  int get fastingEveningMinute => _fastingEveningMinute;
  int get streakCount => _streakCount;
  SyncStatus get syncStatus => _syncStatus;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get signedInUser => _signedInUser;
  String get quoteArabic => QuotesService.instance.quoteArabic;
  String get quoteAuthor => QuotesService.instance.quoteAuthor;
  bool get quoteLoading => QuotesService.instance.isLoading;
  bool get quoteConfigured => QuotesService.instance.isConfigured;
  String get quoteError => QuotesService.instance.quoteError;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _startOnSaturday         = prefs.getBool('start_saturday') ?? true;
    _arabicMode              = prefs.getBool('arabic_mode') ?? true;
    _isDarkMode              = prefs.getBool('is_dark_mode') ?? false;
    _notificationsEnabled    = prefs.getBool('notif_enabled') ?? true;
    _reminderHour            = prefs.getInt('reminder_hour') ?? 18;
    _reminderMinute          = prefs.getInt('reminder_minute') ?? 0;
    _fastingRemindersEnabled = prefs.getBool('fasting_notif_enabled') ?? true;
    _fastingMorningHour      = prefs.getInt('fasting_morning_hour') ?? 7;
    _fastingMorningMinute    = prefs.getInt('fasting_morning_min') ?? 0;
    _fastingMiddayHour       = prefs.getInt('fasting_midday_hour') ?? 12;
    _fastingMiddayMinute     = prefs.getInt('fasting_midday_min') ?? 0;
    _fastingEveningHour      = prefs.getInt('fasting_evening_hour') ?? 20;
    _fastingEveningMinute    = prefs.getInt('fasting_evening_min') ?? 0;

    await OneDriveService.instance.loadConfig();
    await QuotesService.instance.loadConfig();
    await loadMonthTasks();
    await _computeStreak();

    try {
      await NotificationService.instance.init();
      // Schedule Quran reminder
      await NotificationService.instance.scheduleDailyReminder(
        hour: _reminderHour, minute: _reminderMinute, enabled: _notificationsEnabled,
      );
      // Schedule fasting reminders
      await _scheduleFastingReminders();
    } catch (e) {
      debugPrint('Notification init error: $e');
    }

    _isLoading = false;
    notifyListeners();

    // Fetch daily quote
    QuotesService.instance.fetchQuote();

    if (OneDriveService.instance.isSignedIn) {
      _syncInBackground();
    } else {
      _syncStatus = SyncStatus.notConfigured;
      notifyListeners();
    }
  }

  Future<void> _scheduleFastingReminders() async {
    await NotificationService.instance.scheduleFastingReminders(
      enabled: _fastingRemindersEnabled,
      morningHour: _fastingMorningHour,   morningMinute: _fastingMorningMinute,
      middayHour: _fastingMiddayHour,     middayMinute: _fastingMiddayMinute,
      eveningHour: _fastingEveningHour,   eveningMinute: _fastingEveningMinute,
    );
  }

  Future<void> setFastingRemindersEnabled(bool val) async {
    _fastingRemindersEnabled = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fasting_notif_enabled', val);
    await _scheduleFastingReminders();
    notifyListeners();
  }

  Future<void> setFastingMorningTime(int hour, int minute) async {
    _fastingMorningHour = hour; _fastingMorningMinute = minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('fasting_morning_hour', hour);
    await prefs.setInt('fasting_morning_min', minute);
    await _scheduleFastingReminders();
    notifyListeners();
  }

  Future<void> setFastingMiddayTime(int hour, int minute) async {
    _fastingMiddayHour = hour; _fastingMiddayMinute = minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('fasting_midday_hour', hour);
    await prefs.setInt('fasting_midday_min', minute);
    await _scheduleFastingReminders();
    notifyListeners();
  }

  Future<void> setFastingEveningTime(int hour, int minute) async {
    _fastingEveningHour = hour; _fastingEveningMinute = minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('fasting_evening_hour', hour);
    await prefs.setInt('fasting_evening_min', minute);
    await _scheduleFastingReminders();
    notifyListeners();
  }

  Future<void> _syncInBackground() async {
    if (!OneDriveService.instance.isSignedIn) return;
    _syncStatus = SyncStatus.syncing;
    notifyListeners();
    try {
      _signedInUser ??= await OneDriveService.instance.getUserName();
      final remoteTasks = await OneDriveService.instance.downloadTasks();
      if (remoteTasks == null) { _syncStatus = SyncStatus.error; notifyListeners(); return; }
      int mergedCount = 0;
      for (final remote in remoteTasks) {
        final updated = await DatabaseHelper.instance.mergeRemoteTask(remote);
        if (updated) mergedCount++;
      }
      final allLocal = await DatabaseHelper.instance.getAllTasks();
      await OneDriveService.instance.uploadTasks(allLocal);
      if (mergedCount > 0) { _cachedMonth = null; await loadMonthTasks(); await _computeStreak(); }
      _lastSyncTime = DateTime.now();
      _syncStatus = SyncStatus.success;
      notifyListeners();
    } catch (e) {
      _syncStatus = SyncStatus.error;
      notifyListeners();
    }
  }

  Future<void> syncNow() async => _syncInBackground();

  Future<void> loadMonthTasks() async {
    if (_cachedMonth != null &&
        _cachedMonth!.year == _focusedMonth.year &&
        _cachedMonth!.month == _focusedMonth.month) return;
    _monthTasks = await DatabaseHelper.instance.getTasksForMonth(
        _focusedMonth.year, _focusedMonth.month);
    _cachedMonth = _focusedMonth;
    notifyListeners();
  }

  Future<void> _computeStreak() async {
    int streak = 0;
    DateTime day = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final task = await DatabaseHelper.instance.getTask(_dateKey(day));
      if (task != null && task.status == 1) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else break;
    }
    _streakCount = streak;
  }

  void selectDate(DateTime date) { _selectedDate = date; notifyListeners(); }

  void goToToday() {
    _focusedMonth = DateTime.now(); _selectedDate = DateTime.now();
    _cachedMonth = null; loadMonthTasks();
  }

  void goToPreviousMonth() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    _cachedMonth = null; loadMonthTasks();
  }

  void goToNextMonth() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    _cachedMonth = null; loadMonthTasks();
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';

  DayTask? getTask(DateTime date) => _monthTasks[_dateKey(date)];
  DayTask? get selectedDayTask => getTask(_selectedDate);

  Future<void> updateTask(DateTime date, String text, int status) async {
    final key = _dateKey(date);
    final task = DayTask(date: key, taskText: text, status: status);
    _monthTasks[key] = task;
    notifyListeners();
    await DatabaseHelper.instance.upsertTask(task);
    _pushTaskToCloud(task);
    await _computeStreak();
    notifyListeners();
  }

  Future<void> quickToggleStatus(DateTime date) async {
    final key = _dateKey(date);
    final existing = _monthTasks[key];
    if (existing == null) return;
    final updated = DayTask(date: key, taskText: existing.taskText,
        status: existing.status == 1 ? 0 : 1);
    _monthTasks[key] = updated;
    notifyListeners();
    await DatabaseHelper.instance.upsertTask(updated);
    _pushTaskToCloud(updated);
    await _computeStreak();
    notifyListeners();
  }

  Future<void> _pushTaskToCloud(DayTask task) async {
    if (!OneDriveService.instance.isSignedIn) return;
    final all = await DatabaseHelper.instance.getAllTasks();
    OneDriveService.instance.uploadTasks(all);
  }

  Future<void> deleteTask(DateTime date) async {
    final key = _dateKey(date);
    await DatabaseHelper.instance.deleteTask(key);
    _monthTasks.remove(key);
    notifyListeners();
    _pushTaskToCloud(DayTask(date: key, taskText: '', status: 0));
  }

  Future<void> toggleDarkMode(bool val) async {
    _isDarkMode = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', val);
    notifyListeners();
  }

  Future<void> setStartOnSaturday(bool val) async {
    _startOnSaturday = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('start_saturday', val);
    notifyListeners();
  }

  Future<void> setArabicMode(bool val) async {
    _arabicMode = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('arabic_mode', val);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool val) async {
    _notificationsEnabled = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_enabled', val);
    await NotificationService.instance.scheduleDailyReminder(
        hour: _reminderHour, minute: _reminderMinute, enabled: val);
    notifyListeners();
  }

  Future<void> setReminderTime(int hour, int minute) async {
    _reminderHour = hour; _reminderMinute = minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_hour', hour);
    await prefs.setInt('reminder_minute', minute);
    await NotificationService.instance.scheduleDailyReminder(
        hour: hour, minute: minute, enabled: _notificationsEnabled);
    notifyListeners();
  }

  String? _normalizeDate(String raw) {
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) return raw;
    final m = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(raw);
    if (m != null) {
      return '${m.group(3)}-${m.group(1)!.padLeft(2,'0')}-${m.group(2)!.padLeft(2,'0')}';
    }
    return null;
  }

  Future<void> bulkUploadTasks(List<List<dynamic>> rows) async {
    _isLoading = true;
    notifyListeners();
    _monthTasks = {};
    final tasks = <DayTask>[];
    for (var row in rows) {
      if (row.isEmpty) continue;
      final dateStr = _normalizeDate(row[0].toString().trim());
      if (dateStr == null) continue;
      final newText = row.length > 1 ? row[1].toString().trim() : '';
      final text = newText.isEmpty ? ' ' : newText;
      final existing = await DatabaseHelper.instance.getTask(dateStr);
      int status = 0;
      if (existing != null && existing.taskText.trim() == text.trim()) {
        status = existing.status;
      }
      final task = DayTask(date: dateStr, taskText: text, status: status);
      await DatabaseHelper.instance.upsertTask(task);
      tasks.add(task);
    }
    if (tasks.isNotEmpty) OneDriveService.instance.uploadTasks(tasks);
    _cachedMonth = null;
    await loadMonthTasks();
    await _computeStreak();
    _isLoading = false;
    notifyListeners();
  }

  Future<List<List<String>>> exportTasksAsCsv() async {
    final all = await DatabaseHelper.instance.getAllTasks();
    return [
      ['التاريخ', 'المهمة', 'الحالة'],
      ...all.map((t) => [t.date, t.taskText.trim(), t.status == 1 ? 'منجزة' : 'غير منجزة']),
    ];
  }

  Map<String, int> get monthSummary {
    int done = 0, notDone = 0;
    for (final t in _monthTasks.values) { if (t.status == 1) done++; else notDone++; }
    return {'total': _monthTasks.length, 'done': done, 'notDone': notDone};
  }

  double get monthProgress {
    final total = _monthTasks.length;
    if (total == 0) return 0.0;
    return _monthTasks.values.where((t) => t.status == 1).length / total;
  }
}
