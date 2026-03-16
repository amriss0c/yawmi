class DayTask {
  final String date;
  final String taskText;
  final int status;
  final String updatedAt;

  DayTask({
    required this.date,
    required this.taskText,
    required this.status,
    String? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().toUtc().toIso8601String();

  Map<String, dynamic> toMap() => {
    'date': date,
    'taskText': taskText,
    'status': status,
    'updatedAt': updatedAt,
  };

  Map<String, dynamic> toSupabaseMap() => {
    'date': date,
    'task_text': taskText,
    'status': status,
    'updated_at': updatedAt,
  };

  factory DayTask.fromMap(Map<String, dynamic> map) => DayTask(
    date: map['date']?.toString() ?? '',
    taskText: map['taskText']?.toString() ?? map['task_text']?.toString() ?? '',
    status: map['status'] is int ? map['status'] : int.tryParse(map['status'].toString()) ?? 0,
    updatedAt: map['updatedAt']?.toString() ?? map['updated_at']?.toString(),
  );

  bool isNewerThan(DayTask other) {
    try {
      return DateTime.parse(updatedAt).isAfter(DateTime.parse(other.updatedAt));
    } catch (_) {
      return true;
    }
  }
}
