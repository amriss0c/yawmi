class DayTask {
  final String date;     // Format: YYYY-MM-DD
  final String taskText;
  final int status;      // 0 = Not Done, 1 = Done

  DayTask({required this.date, required this.taskText, required this.status});

  Map<String, dynamic> toMap() => {'date': date, 'taskText': taskText, 'status': status};

  factory DayTask.fromMap(Map<String, dynamic> map) {
    return DayTask(
      date: map['date'] as String? ?? '',
      taskText: map['taskText'] as String? ?? '',
      status: map['status'] as int? ?? 0,
    );
  }
}