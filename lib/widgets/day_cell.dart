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

  const DayCell({
    super.key, required this.date, this.task, required this.isToday,
    required this.isSelected, required this.onTap, required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color indicatorColor;
    if (task == null) {
      indicatorColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    } else {
      indicatorColor = task!.status == 1 ? Colors.green : Colors.red;
    }

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A6B4A).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A6B4A) : theme.dividerColor,
            width: isSelected ? 2 : 0.8,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 4),
            Column(
              children: [
                Text('${date.day}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(HijriHelper.getHijriDay(date), style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                    const SizedBox(width: 2),
                    Text(HijriHelper.getFullHijriMonthName(date), style: TextStyle(fontSize: 9, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ],
            ),
            Container(height: 6, width: double.infinity, color: indicatorColor),
          ],
        ),
      ),
    );
  }
}