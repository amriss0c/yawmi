import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/database_helper.dart';
import '../models/day_task.dart';

class TaskProvider extends ChangeNotifier {
  Map<String, DayTask> _monthTasks = {};
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  bool _startOnSaturday = true; 
  bool _arabicMode = true;
  bool _isDarkMode = false;
  bool _isLoading = false;

  Map<String, DayTask> get monthTasks => _monthTasks;
  DateTime get focusedMonth => _focusedMonth;
  DateTime get selectedDate => _selectedDate;
  bool get startOnSaturday => _startOnSaturday;
  bool get arabicMode => _arabicMode;

  Future<void> setArabicMode(bool value) async {
    _arabicMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('arabic_mode', value);
    notifyListeners();
  }
  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    _startOnSaturday = prefs.getBool('start_saturday') ?? true;
    _arabicMode = prefs.getBool('arabic_mode') ?? true;
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    await loadMonthTasks();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMonthTasks() async {
    _monthTasks = await DatabaseHelper.instance.getTasksForMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void goToToday() {
    _focusedMonth = DateTime.now();
    _selectedDate = DateTime.now();
    loadMonthTasks();
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

  String _dateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
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

  Future<void> bulkUploadTasks(List<List<dynamic>> rows) async {
    _isLoading = true;
    notifyListeners();
    for (var row in rows) {
      if (row.length >= 2) {
        final dateStr = row[0].toString();
        final taskText = row[1].toString();
        await DatabaseHelper.instance.upsertTask(
          DayTask(date: dateStr, taskText: taskText, status: 0),
        );
      }
    }
    await loadMonthTasks();
    _isLoading = false;
    notifyListeners();
  }
}