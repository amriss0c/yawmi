import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/task_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A6B4A),
          title: const Text('الإعدادات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Consumer<TaskProvider>(
          builder: (context, provider, _) {
            return ListView(
              children: [
                _sectionHeader('المظهر'),
                SwitchListTile(
                  title: const Text('الوضع الليلي'),
                  secondary: Icon(provider.isDarkMode ? Icons.dark_mode : Icons.light_mode, color: const Color(0xFF1A6B4A)),
                  value: provider.isDarkMode,
                  onChanged: (v) => provider.toggleDarkMode(v),
                ),

                const Divider(),
                _sectionHeader('البيانات'),
                ListTile(
                  title: const Text('استيراد مهام من CSV'),
                  subtitle: const Text('يستبدل جميع المهام الحالية'),
                  leading: const Icon(Icons.upload_file, color: Color(0xFF1A6B4A)),
                  onTap: () => _handleCsvUpload(context, provider),
                ),
                ListTile(
                  title: const Text('تصدير المهام إلى CSV'),
                  subtitle: const Text('نسخ احتياطي لجميع المهام'),
                  leading: const Icon(Icons.download, color: Color(0xFF1A6B4A)),
                  onTap: () => _handleCsvExport(context, provider),
                ),
                if (provider.isLoading) const LinearProgressIndicator(),

                const Divider(),
                _sectionHeader('التفضيلات'),
                SwitchListTile(
                  title: const Text('بداية الأسبوع يوم السبت'),
                  value: provider.startOnSaturday,
                  onChanged: (v) => provider.setStartOnSaturday(v),
                ),
                SwitchListTile(
                  title: const Text('اللغة العربية'),
                  value: provider.arabicMode,
                  onChanged: (v) => provider.setArabicMode(v),
                ),

                const Divider(),
                _sectionHeader('التذكيرات'),
                SwitchListTile(
                  title: const Text('تفعيل التذكير اليومي'),
                  secondary: const Icon(Icons.notifications, color: Color(0xFF1A6B4A)),
                  value: provider.notificationsEnabled,
                  onChanged: (v) => provider.setNotificationsEnabled(v),
                ),
                ListTile(
                  title: const Text('وقت التذكير'),
                  subtitle: Text(
                    '${provider.reminderHour.toString().padLeft(2, '0')}:${provider.reminderMinute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Color(0xFF1A6B4A), fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  leading: const Icon(Icons.access_time, color: Color(0xFF1A6B4A)),
                  enabled: provider.notificationsEnabled,
                  onTap: provider.notificationsEnabled
                      ? () => _pickReminderTime(context, provider)
                      : null,
                ),

                const Divider(),
                _sectionHeader('عن التطبيق'),
                const ListTile(
                  title: Text('وردي - Wirdi'),
                  subtitle: Text('النسخة الاحترافية v3.0\nتتبع الورد اليومي'),
                  leading: Icon(Icons.verified, color: Color(0xFF1A6B4A)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleCsvUpload(BuildContext context, TaskProvider provider) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result != null) {
        final file = File(result.files.single.path!);
        final fields = await file.openRead()
            .transform(utf8.decoder)
            .transform(const CsvToListConverter())
            .toList();
        await provider.bulkUploadTasks(fields);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم الاستيراد بنجاح ✅')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ في الملف: UTF-8 مطلوب')));
      }
    }
  }

  Future<void> _handleCsvExport(BuildContext context, TaskProvider provider) async {
    try {
      final rows = await provider.exportTasksAsCsv();
      if (rows.length <= 1) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا توجد مهام للتصدير')));
        }
        return;
      }
      final csv = const ListToCsvConverter().convert(rows);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/wirdi_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv, encoding: utf8);
      await Share.shareXFiles([XFile(file.path)], text: 'وردي — تصدير المهام');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ في التصدير')));
      }
    }
  }

  Future<void> _pickReminderTime(BuildContext context, TaskProvider provider) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: provider.reminderHour, minute: provider.reminderMinute),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );
    if (picked != null) {
      await provider.setReminderTime(picked.hour, picked.minute);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            'تم ضبط التذكير على ${picked.hour.toString().padLeft(2,'0')}:${picked.minute.toString().padLeft(2,'0')}')));
      }
    }
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: const TextStyle(
          color: Color(0xFF1A6B4A), fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}
