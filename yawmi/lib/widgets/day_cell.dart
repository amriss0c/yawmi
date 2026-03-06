// lib/widgets/day_cell.dart

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
    super.key,
    required this.date,
    this.task,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine the indicator color based on task status
    Color indicatorColor;
    if (task == null) {
      indicatorColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300; // Grey: No Task
    } else {
      indicatorColor = task!.status == 1 ? Colors.green : Colors.red; // Green: Done, Red: Not Done
    }

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        clipBehavior: Clip.antiAlias, // Ensures the bottom bar follows border radius
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A6B4A).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A6B4A) : theme.dividerColor,
            width: isSelected ? 2 : 0.8,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Pushes indicator to bottom
          children: [
            const SizedBox(height: 8), // Top spacing
            Column(
              children: [
                // GREGORIAN DAY (Primary)
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                // HIJRI INFO (Secondary)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 2,
                    children: [
                      Text(
                        HijriHelper.getHijriDay(date),
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                      Text(
                        HijriHelper.getFullHijriMonthName(date),
                        style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // FULL-WIDTH INDICATOR BAR
            Container(
              height: 6, // Thickness of the bar
              width: double.infinity,
              color: indicatorColor,
            ),
          ],
        ),
      ),
    );
  }
}