import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/task_provider.dart';
import '../services/quotes_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _geminiKeyController = TextEditingController();

  @override
  void dispose() {
    _geminiKeyController.dispose();
    super.dispose();
  }


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


                // ── QUOTES ───────────────────────────────────────────
              const Divider(),
              _sectionHeader('اقتباسات يومية بالذكاء الاصطناعي'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('مفتاح Gemini API',
                        style: TextStyle(fontSize: 12, color: Color(0xFF1A6B4A),
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('احصل على مفتاح مجاني من aistudio.google.com',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _geminiKeyController,
                      obscureText: true,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        hintText: 'AIzaSy...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.save, color: Color(0xFF1A6B4A)),
                          onPressed: () async {
                            await QuotesService.instance
                                .saveApiKey(_geminiKeyController.text);
                            QuotesService.instance.fetchQuote(() {});
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('تم الحفظ ✅ جارٍ تحميل اقتباس...')));
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('الفئات المفعّلة',
                        style: TextStyle(fontSize: 12, color: Color(0xFF1A6B4A),
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    StatefulBuilder(
                      builder: (ctx, setChipState) => Wrap(
                        spacing: 8, runSpacing: 6,
                        children: QuotesService.categoryTags.keys.map((cat) {
                          final enabled = QuotesService.instance
                              .enabledCategories.contains(cat);
                          return FilterChip(
                            label: Text(cat,
                                style: const TextStyle(fontSize: 11)),
                            selected: enabled,
                            selectedColor:
                                const Color(0xFF1A6B4A).withOpacity(0.15),
                            checkmarkColor: const Color(0xFF1A6B4A),
                            onSelected: (val) async {
                              final cats = List<String>.from(
                                  QuotesService.instance.enabledCategories);
                              if (val) {
                                cats.add(cat);
                              } else {
                                if (cats.length <= 1) return;
                                cats.remove(cat);
                              }
                              await QuotesService.instance.saveCategories(cats);
                              setChipState(() {});
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

                // ── FASTING REMINDERS ────────────────────────────────
              const Divider(),
              _sectionHeader('تذكيرات الصيام'),
              SwitchListTile(
                secondary: const Icon(Icons.nightlight_round, color: Color(0xFF1A6B4A)),
                title: const Text('تذكير بصيام الأيام الفاضلة'),
                subtitle: const Text('الاثنين والخميس وأيام البيض — اليوم السابق'),
                value: provider.fastingRemindersEnabled,
                onChanged: (v) => provider.setFastingRemindersEnabled(v),
              ),
              if (provider.fastingRemindersEnabled) ...[
                _buildTimeTile(
                  context,
                  Icons.wb_sunny_outlined,
                  'التذكير الصباحي',
                  provider.fastingMorningHour,
                  provider.fastingMorningMinute,
                  (t) => provider.setFastingMorningTime(t.hour, t.minute),
                ),
                _buildTimeTile(
                  context,
                  Icons.wb_sunny,
                  'تذكير الظهيرة',
                  provider.fastingMiddayHour,
                  provider.fastingMiddayMinute,
                  (t) => provider.setFastingMiddayTime(t.hour, t.minute),
                ),
                _buildTimeTile(
                  context,
                  Icons.nights_stay,
                  'التذكير المسائي',
                  provider.fastingEveningHour,
                  provider.fastingEveningMinute,
                  (t) => provider.setFastingEveningTime(t.hour, t.minute),
                ),
              ],

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


  Widget _buildTimeTile(
    BuildContext context,
    IconData icon,
    String label,
    int hour,
    int minute,
    Function(TimeOfDay) onPicked,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1A6B4A)),
      title: Text(label),
      subtitle: Text(
        "${hour.toString().padLeft(2,'0')}:${minute.toString().padLeft(2,'0')}",
        style: const TextStyle(
            color: Color(0xFF1A6B4A), fontWeight: FontWeight.bold, fontSize: 15),
      ),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: minute),
          builder: (ctx, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
        );
        if (picked != null) onPicked(picked);
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: const TextStyle(
          color: Color(0xFF1A6B4A), fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}
