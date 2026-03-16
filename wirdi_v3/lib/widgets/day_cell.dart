import 'package:flutter/material.dart';
import '../models/day_task.dart';
import '../utils/hijri_helper.dart';

class DayCell extends StatelessWidget {
  final DateTime date;
  final DayTask? task;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback? onLongPress;

  const DayCell({
    super.key,
    required this.date,
    this.task,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
    required this.onDoubleTap,
    this.onLongPress,
  });

  Color _getIndicatorColor(bool isDark) {
    final today = DateTime.now();
    final isPast = date.isBefore(DateTime(today.year, today.month, today.day));

    if (task == null || task!.taskText.trim().isEmpty) {
      return isDark ? const Color(0xFF2C2C2C) : Colors.white;
    }
    if (task!.status == 1) return Colors.green;
    if (isPast) return Colors.red;
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final indicatorColor = _getIndicatorColor(isDark);

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1A6B4A).withOpacity(0.1)
              : isToday
                  ? const Color(0xFF1A6B4A).withOpacity(0.05)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isToday
                ? const Color(0xFF1A6B4A)
                : isSelected
                    ? const Color(0xFF2E9E6E)
                    : theme.dividerColor,
            width: isSelected || isToday ? 2 : 0.8,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 6),
            Column(
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isToday
                        ? const Color(0xFF1A6B4A)
                        : theme.textTheme.bodyLarge?.color,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        HijriHelper.getHijriDay(date),
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          HijriHelper.getFullHijriMonthName(date),
                          style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: indicatorColor,
                border: indicatorColor == Colors.white ||
                        indicatorColor == const Color(0xFF2C2C2C)
                    ? Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5))
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
