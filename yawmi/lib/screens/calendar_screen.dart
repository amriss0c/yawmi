// lib/screens/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../utils/hijri_helper.dart';
import '../widgets/day_cell.dart';
import '../widgets/day_detail_sheet.dart';
import 'settings_screen.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Accessing the theme for dynamic styling
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // Dynamic background color
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A6B4A),
          elevation: 0,
          title: const Text('يومي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.today, color: Colors.white),
              onPressed: () => context.read<TaskProvider>().goToToday(),
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
        body: Consumer<TaskProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                _buildMonthHeader(context, provider),
                _buildWeekDayHeaders(provider),
                Expanded(
                  child: _buildCalendarGrid(context, provider),
                ),
                _buildSelectedTaskBox(context, provider), // Reactive Detail Box
                _buildLegend(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context, TaskProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            HijriHelper.getGregorianMonthName(provider.focusedMonth, true),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            HijriHelper.getHijriMonthRange(provider.focusedMonth, true),
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDayHeaders(TaskProvider provider) {
    final days = provider.startOnSaturday 
        ? ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'] 
        : ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'];
    
    return Row(
      children: days.map((day) => Expanded(
        child: Center(
          child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A6B4A))),
        ),
      )).toList(),
    );
  }

  Widget _buildCalendarGrid(BuildContext context, TaskProvider provider) {
    final firstDay = DateTime(provider.focusedMonth.year, provider.focusedMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(provider.focusedMonth.year, provider.focusedMonth.month);
    
    int offset = (provider.startOnSaturday) 
        ? (firstDay.weekday == 6 ? 0 : firstDay.weekday == 7 ? 1 : firstDay.weekday + 1)
        : (firstDay.weekday == 7 ? 0 : firstDay.weekday);

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: daysInMonth + offset,
      itemBuilder: (context, index) {
        if (index < offset) return const SizedBox.shrink();
        final date = DateTime(provider.focusedMonth.year, provider.focusedMonth.month, index - offset + 1);
        
        return DayCell(
          date: date,
          task: provider.getTask(date),
          isToday: DateUtils.isSameDay(date, DateTime.now()),
          isSelected: DateUtils.isSameDay(date, provider.selectedDate),
          onTap: () => provider.selectDate(date),
          onDoubleTap: () => _openDayDetail(context, date),
        );
      },
    );
  }

  Widget _buildSelectedTaskBox(BuildContext context, TaskProvider provider) {
    final task = provider.selectedDayTask;
    final hijriStr = HijriHelper.getFullHijriDate(provider.selectedDate);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // DYNAMIC COLOR
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: const Color(0xFF1A6B4A).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(hijriStr, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (task != null) 
                Icon(
                  task.status == 1 ? Icons.check_circle : Icons.pending,
                  color: task.status == 1 ? Colors.green : Colors.orange,
                ),
            ],
          ),
          const Divider(),
          Text(
            task?.taskText ?? 'لا توجد مهام مسجلة لهذا اليوم',
            style: TextStyle(
              fontSize: 16,
              color: task != null ? null : Colors.grey,
              fontStyle: task != null ? FontStyle.normal : FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('تعديل التفاصيل'),
              onPressed: () => _openDayDetail(context, provider.selectedDate),
            ),
          )
        ],
      ),
    );
  }

  void _openDayDetail(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DayDetailSheet(date: date),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(Colors.green, 'منجز'),
          const SizedBox(width: 20),
          _legendItem(Colors.red, 'غير منجز'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}