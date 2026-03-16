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
  int _streakCount = 0;

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
  int get streakCount => _streakCount;

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
    await _computeStreak();
    try {
      await NotificationService.instance.init();
    } catch (e) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMonthTasks() async {
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

  Future<void> _computeStreak() async {
    int streak = 0;
    DateTime day = DateTime.now();
    // Go back day by day until we find a day without a completed task
    for (int i = 0; i < 365; i++) {
      final key = _dateKey(day);
      final task = await DatabaseHelper.instance.getTask(key);
      if (task != null && task.status == 1) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    _streakCount = streak;
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
    _cachedMonth = null;
    loadMonthTasks();
  }

  void goToNextMonth() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    _cachedMonth = null;
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
    await _computeStreak();
    notifyListeners();
  }

  Future<void> quickToggleStatus(DateTime date) async {
    final key = _dateKey(date);
    final existing = _monthTasks[key];
    if (existing == null) return; // No task to toggle
    final newStatus = existing.status == 1 ? 0 : 1;
    final updated = DayTask(date: key, taskText: existing.taskText, status: newStatus);
    _monthTasks[key] = updated;
    notifyListeners();
    await DatabaseHelper.instance.upsertTask(updated);
    await _computeStreak();
    notifyListeners();
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
    notifyListeners();
  }

  Future<void> setReminderTime(int hour, int minute) async {
    _reminderHour = hour;
    _reminderMinute = minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_hour', hour);
    await prefs.setInt('reminder_minute', minute);
    notifyListeners();
  }

  String? _normalizeDate(String raw) {
    final isoRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (isoRegex.hasMatch(raw)) return raw;
    final mdyRegex = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');
    final match = mdyRegex.firstMatch(raw);
    if (match != null) {
      final m = match.group(1)!.padLeft(2, '0');
      final d = match.group(2)!.padLeft(2, '0');
      final y = match.group(3)!;
      return '$y-$m-$d';
    }
    return null;
  }

  Future<void> bulkUploadTasks(List<List<dynamic>> rows) async {
    _isLoading = true;
    notifyListeners();
    await DatabaseHelper.instance.deleteAllTasks();
    _monthTasks = {};
    for (var row in rows) {
      if (row.isEmpty) continue;
      final dateRaw = row[0].toString().trim();
      if (dateRaw.isEmpty) continue;
      final dateStr = _normalizeDate(dateRaw);
      if (dateStr == null) continue;
      final taskText = row.length > 1 ? row[1].toString().trim() : '';
      await DatabaseHelper.instance.upsertTask(
        DayTask(date: dateStr, taskText: taskText.isEmpty ? ' ' : taskText, status: 0),
      );
    }
    _cachedMonth = null;
    await loadMonthTasks();
    await _computeStreak();
    _isLoading = false;
    notifyListeners();
  }

  // Export all tasks as CSV rows
  Future<List<List<String>>> exportTasksAsCsv() async {
    final allTasks = await DatabaseHelper.instance.getAllTasks();
    final rows = <List<String>>[
      ['التاريخ', 'المهمة', 'الحالة'], // header
    ];
    for (final task in allTasks) {
      rows.add([task.date, task.taskText.trim(), task.status == 1 ? 'منجزة' : 'غير منجزة']);
    }
    return rows;
  }

  Map<String, int> get monthSummary {
    int done = 0, notDone = 0, total = _monthTasks.length;
    for (final task in _monthTasks.values) {
      if (task.status == 1) done++;
      else notDone++;
    }
    return {'total': total, 'done': done, 'notDone': notDone};
  }

  double get monthProgress {
    final total = _monthTasks.length;
    if (total == 0) return 0.0;
    final done = _monthTasks.values.where((t) => t.status == 1).length;
    return done / total;
  }
}
