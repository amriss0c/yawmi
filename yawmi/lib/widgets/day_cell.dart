import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
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

  static const _tealBg     = Color(0xFFE0F7FA);
  static const _tealBorder = Color(0xFF80DEEA);
  static const _tealText   = Color(0xFF006064);
  static const _goldBg     = Color(0xFFFFF8E1);
  static const _goldBorder = Color(0xFFFFE082);
  static const _goldText   = Color(0xFFE65100);

  String _fastType() {
    final isMT = date.weekday == 1 || date.weekday == 4;
    final hijri = HijriCalendar.fromDate(date);
    final isAB  = hijri.hDay == 13 || hijri.hDay == 14 || hijri.hDay == 15;
    if (isMT && isAB) return 'both';
    if (isMT)  return 'mt';
    if (isAB)  return 'ab';
    return 'none';
  }

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
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ft     = _fastType();
    final indicatorColor = _getIndicatorColor(isDark);

    Color cellBg;
    Color cellBorder;
    Color dayNumColor;

    if (isSelected) {
      cellBg      = const Color(0xFF1A6B4A).withOpacity(0.1);
      cellBorder  = const Color(0xFF2E9E6E);
      dayNumColor = const Color(0xFF1A6B4A);
    } else if (isToday) {
      cellBg      = const Color(0xFF1A6B4A).withOpacity(0.05);
      cellBorder  = const Color(0xFF1A6B4A);
      dayNumColor = const Color(0xFF1A6B4A);
    } else if (ft == 'mt' || ft == 'both') {
      cellBg      = isDark ? const Color(0xFF0D3B40) : _tealBg;
      cellBorder  = isDark ? const Color(0xFF4DD0E1) : _tealBorder;
      dayNumColor = isDark ? const Color(0xFF80DEEA) : _tealText;
    } else if (ft == 'ab') {
      cellBg      = isDark ? const Color(0xFF3E2F00) : _goldBg;
      cellBorder  = isDark ? const Color(0xFFFFD54F) : _goldBorder;
      dayNumColor = isDark ? const Color(0xFFFFE082) : _goldText;
    } else {
      cellBg      = Colors.transparent;
      cellBorder  = theme.dividerColor;
      dayNumColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    }

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cellBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: cellBorder,
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
                    color: dayNumColor,
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
