import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/day_cell.dart';
import '../widgets/day_detail_sheet.dart';
import '../utils/hijri_helper.dart';
import 'settings_screen.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isWide = width > 700;
            final isMedium = width > 500 && width <= 700;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                appBar: _buildAppBar(context, provider, isWide),
                body: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity == null) return;
                    // RTL: drag right = previous month, drag left = next month
                    if (details.primaryVelocity! > 300) {
                      HapticFeedback.lightImpact();
                      provider.goToPreviousMonth();
                    } else if (details.primaryVelocity! < -300) {
                      HapticFeedback.lightImpact();
                      provider.goToNextMonth();
                    }
                  },
                  child: isWide
                      ? _buildWideLayout(context, provider)
                      : _buildNarrowLayout(context, provider, isMedium),
                ),
              ),
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, TaskProvider provider, bool isWide) {
    final focusedDate = provider.focusedMonth;
    return AppBar(
      backgroundColor: const Color(0xFF1A6B4A),
      title: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                HijriHelper.getGregorianMonthName(focusedDate, true),
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              Text(
                HijriHelper.getHijriMonthRange(focusedDate, true),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Streak counter
          if (provider.streakCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '${provider.streakCount}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          if (isWide) ...[
            const SizedBox(width: 12),
            _summaryChip(Icons.check_circle, '${provider.monthSummary['done']}', Colors.greenAccent),
            const SizedBox(width: 6),
            _summaryChip(Icons.cancel, '${provider.monthSummary['notDone']}', Colors.redAccent),
          ],
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.today, color: Colors.white),
          onPressed: () => provider.goToToday(),
          tooltip: 'اليوم',
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _summaryChip(IconData icon, String count, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 3),
        Text(count, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context, TaskProvider provider, bool isMedium) {
    final focusedDate = provider.focusedMonth;
    final daysInMonth = DateUtils.getDaysInMonth(focusedDate.year, focusedDate.month);
    final firstDay = DateTime(focusedDate.year, focusedDate.month, 1);

    int weekdayOffset = firstDay.weekday;
    if (provider.startOnSaturday) {
      weekdayOffset = (firstDay.weekday % 7) + 1;
      if (weekdayOffset > 7) weekdayOffset = 1;
    }

    final List<String> weekDays = provider.startOnSaturday
        ? ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج']
        : ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];

    final cellAspect = isMedium ? 0.85 : 0.75;

    return Column(
      children: [
        _buildWeekHeaders(provider, weekDays),
        _buildProgressBar(provider),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(6),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: cellAspect,
            ),
            itemCount: daysInMonth + (weekdayOffset - 1),
            itemBuilder: (context, index) {
              if (index < weekdayOffset - 1) return const SizedBox.shrink();
              final day = index - (weekdayOffset - 2);
              final date = DateTime(focusedDate.year, focusedDate.month, day);
              return DayCell(
                date: date,
                task: provider.getTask(date),
                isToday: DateUtils.isSameDay(date, DateTime.now()),
                isSelected: DateUtils.isSameDay(date, provider.selectedDate),
                onTap: () => provider.selectDate(date),
                onDoubleTap: () => _showDetails(context, date),
                onLongPress: () => _quickToggle(context, provider, date),
              );
            },
          ),
        ),
        _buildTaskBox(context, provider),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context, TaskProvider provider) {
    final focusedDate = provider.focusedMonth;
    final daysInMonth = DateUtils.getDaysInMonth(focusedDate.year, focusedDate.month);
    final firstDay = DateTime(focusedDate.year, focusedDate.month, 1);

    int weekdayOffset = firstDay.weekday;
    if (provider.startOnSaturday) {
      weekdayOffset = (firstDay.weekday % 7) + 1;
      if (weekdayOffset > 7) weekdayOffset = 1;
    }

    final List<String> weekDays = provider.startOnSaturday
        ? ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج']
        : ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 65,
          child: Column(
            children: [
              _buildWeekHeaders(provider, weekDays),
              _buildProgressBar(provider),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(6),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: daysInMonth + (weekdayOffset - 1),
                  itemBuilder: (context, index) {
                    if (index < weekdayOffset - 1) return const SizedBox.shrink();
                    final day = index - (weekdayOffset - 2);
                    final date = DateTime(focusedDate.year, focusedDate.month, day);
                    return DayCell(
                      date: date,
                      task: provider.getTask(date),
                      isToday: DateUtils.isSameDay(date, DateTime.now()),
                      isSelected: DateUtils.isSameDay(date, provider.selectedDate),
                      onTap: () => provider.selectDate(date),
                      onDoubleTap: () => _showDetails(context, date),
                      onLongPress: () => _quickToggle(context, provider, date),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: const Color(0xFF1A6B4A).withOpacity(0.2)),
        Expanded(
          flex: 35,
          child: _buildDetailPanel(context, provider),
        ),
      ],
    );
  }

  Widget _buildProgressBar(TaskProvider provider) {
    final progress = provider.monthProgress;
    final summary = provider.monthSummary;
    if (summary['total'] == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'إنجاز الشهر',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              Text(
                '${summary['done']} / ${summary['total']}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF1A6B4A), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? Colors.green : const Color(0xFF2E9E6E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeaders(TaskProvider provider, List<String> weekDays) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: provider.isDarkMode ? Colors.black26 : Colors.grey[100],
      child: Row(
        children: weekDays.map((day) => Expanded(
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildTaskBox(BuildContext context, TaskProvider provider) {
    final task = provider.selectedDayTask;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hijriStr = HijriHelper.getFullHijriDate(provider.selectedDate);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
          color: isDark ? Colors.black45 : Colors.black12,
          blurRadius: 8, offset: const Offset(0, 3),
        )],
        border: Border.all(color: const Color(0xFF1A6B4A).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(hijriStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              if (task != null)
                Icon(
                  task.status == 1 ? Icons.check_circle : Icons.pending,
                  color: task.status == 1 ? Colors.green : Colors.orange,
                  size: 20,
                ),
            ],
          ),
          const Divider(height: 10),
          Text(
            task != null && task.taskText.trim().isNotEmpty
                ? task.taskText
                : 'لا توجد مهمة مسجلة لهذا اليوم',
            style: TextStyle(
              fontSize: 15,
              color: task != null && task.taskText.trim().isNotEmpty ? null : Colors.grey,
              fontStyle: task != null && task.taskText.trim().isNotEmpty
                  ? FontStyle.normal : FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.edit, size: 15),
                label: const Text('تعديل', style: TextStyle(fontSize: 12)),
                onPressed: () => _showDetails(context, provider.selectedDate),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1A6B4A),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
              ),
              if (task != null) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: Icon(
                    task.status == 1 ? Icons.undo : Icons.check,
                    size: 15,
                  ),
                  label: Text(
                    task.status == 1 ? 'إلغاء الإنجاز' : 'تحديد كمنجزة',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () => _quickToggle(context, provider, provider.selectedDate),
                  style: TextButton.styleFrom(
                    foregroundColor: task.status == 1 ? Colors.orange : Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel(BuildContext context, TaskProvider provider) {
    final task = provider.selectedDayTask;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedDate = provider.selectedDate;
    final hijriStr = HijriHelper.getFullHijriDate(selectedDate);
    final summary = provider.monthSummary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hijriStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(
            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1A6B4A).withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      task?.status == 1 ? Icons.check_circle
                          : task != null ? Icons.pending
                          : Icons.radio_button_unchecked,
                      color: task?.status == 1 ? Colors.green
                          : task != null ? Colors.orange
                          : Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      task?.status == 1 ? 'منجزة'
                          : task != null ? 'غير منجزة'
                          : 'لا توجد مهمة',
                      style: TextStyle(
                        color: task?.status == 1 ? Colors.green
                            : task != null ? Colors.orange
                            : Colors.grey,
                        fontWeight: FontWeight.bold, fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  task != null && task.taskText.trim().isNotEmpty
                      ? task.taskText : 'لا توجد مهمة مسجلة',
                  style: TextStyle(
                    fontSize: 15,
                    color: task != null && task.taskText.trim().isNotEmpty ? null : Colors.grey,
                    fontStyle: task != null && task.taskText.trim().isNotEmpty
                        ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit, size: 15),
                  label: const Text('تعديل'),
                  onPressed: () => _showDetails(context, selectedDate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A6B4A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              if (task != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(task.status == 1 ? Icons.undo : Icons.check, size: 15),
                    label: Text(task.status == 1 ? 'إلغاء' : 'منجزة'),
                    onPressed: () => _quickToggle(context, provider, selectedDate),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: task.status == 1 ? Colors.orange : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),
          const Text('ملخص الشهر', style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A6B4A))),
          const SizedBox(height: 8),
          _buildProgressBar(provider),
          const SizedBox(height: 8),
          _summaryRow(Icons.check_circle, 'منجزة', '${summary['done']}', Colors.green),
          _summaryRow(Icons.cancel, 'غير منجزة', '${summary['notDone']}', Colors.red),
          _summaryRow(Icons.calendar_month, 'إجمالي', '${summary['total']}', Colors.grey),
          if (provider.streakCount > 0) ...[
            const SizedBox(height: 8),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    '${provider.streakCount} يوم متتالي',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
          const Spacer(),
          Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        ],
      ),
    );
  }

  void _quickToggle(BuildContext context, TaskProvider provider, DateTime date) {
    final task = provider.getTask(date);
    if (task == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد مهمة لتحديثها'), duration: Duration(seconds: 1)));
      return;
    }
    HapticFeedback.mediumImpact();
    provider.quickToggleStatus(date);
    final newStatus = task.status == 1 ? 'غير منجزة' : 'منجزة ✅';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم التحديث: $newStatus'), duration: const Duration(seconds: 1)));
  }

  void _showDetails(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DayDetailSheet(date: date),
    );
  }
}
