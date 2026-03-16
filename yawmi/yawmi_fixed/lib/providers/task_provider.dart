import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/database_helper.dart';
import '../models/day_task.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  Map<String, DayTask> _monthTasks = {};
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  DateTime? _cachedMonth;

  bool _startOnSaturday = true;
  bool _arabicMode = true;
  bool _isDarkMode = false;
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  int _reminderHour = 18;
  int _reminderMinute = 0;

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

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    _startOnSaturday = prefs.getBool('start_saturday') ?? true;
    _arabicMode = prefs.getBool('arabic_mode') ?? true;
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    _notificationsEnabled = prefs.getBool('notif_enabled') ?? true;
    _reminderHour = prefs.getInt('reminder_hour') ?? 18;
    _reminderMinute = prefs.getInt('reminder_minute') ?? 0;
    await loadMonthTasks();
    try {
      await NotificationService.instance.init();
      await NotificationService.instance.scheduleDailyReminder(
        hour: _reminderHour,
        minute: _reminderMinute,
        enabled: _notificationsEnabled,
      );
    } catch (e) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMonthTasks() async {
    // Cache: skip reload if same month
    if (_cachedMonth != null &&
        _cachedMonth!.year == _focusedMonth.year &&
        _cachedMonth!.month == _focusedMonth.month) return;
    _monthTasks = await DatabaseHelper.instance.getTasksForMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    _cachedMonth = _focusedMonth;
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void goToToday() {
    _focusedMonth = DateTime.now();
    _selectedDate = DateTime.now();
    _cachedMonth = null;
    loadMonthTasks();
  }

  void goToPreviousMonth() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    loadMonthTasks();
  }

  void goToNextMonth() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    loadMonthTasks();
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DayTask? getTask(DateTime date) => _monthTasks[_dateKey(date)];
  DayTask? get selectedDayTask => getTask(_selectedDate);

  Future<void> updateTask(DateTime date, String text, int status) async {
    final key = _dateKey(date);
    final task = DayTask(date: key, taskText: text, status: status);
    _monthTasks[key] = task;
    notifyListeners();
    await DatabaseHelper.instance.upsertTask(task);
  }

  Future<void> deleteTask(DateTime date) async {
    final key = _dateKey(date);
    await DatabaseHelper.instance.deleteTask(key);
    _monthTasks.remove(key);
    notifyListeners();
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
    try {
      await NotificationService.instance.scheduleDailyReminder(
        hour: _reminderHour, minute: _reminderMinute, enabled: val);
    } catch (e) {}
    notifyListeners();
  }

  Future<void> setReminderTime(int hour, int minute) async {
    _reminderHour = hour;
    _reminderMinute = minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_hour', hour);
    await prefs.setInt('reminder_minute', minute);
    try {
      await NotificationService.instance.scheduleDailyReminder(
        hour: hour, minute: minute, enabled: _notificationsEnabled);
    } catch (e) {}
    notifyListeners();
  }

  Future<void> bulkUploadTasks(List<List<dynamic>> rows) async {
    _isLoading = true;
    notifyListeners();
    for (var row in rows) {
      if (row.isEmpty) continue;
      final dateStr = row[0].toString().trim();
      if (dateStr.isEmpty) continue;
      // Validate date format YYYY-MM-DD
      final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      if (!dateRegex.hasMatch(dateStr)) continue;
      // Ignore all other columns — task text is a space
      await DatabaseHelper.instance.upsertTask(
        DayTask(date: dateStr, taskText: ' ', status: 0),
      );
    }
    _cachedMonth = null;
    await loadMonthTasks();
    _isLoading = false;
    notifyListeners();
  }

  // Monthly progress summary
  Map<String, int> get monthSummary {
    int done = 0, notDone = 0, total = _monthTasks.length;
    for (final task in _monthTasks.values) {
      if (task.status == 1) done++;
      else notDone++;
    }
    return {'total': total, 'done': done, 'notDone': notDone};
  }
}
