// lib/screens/settings_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
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
          title: const Text('الإعدادات', 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Consumer<TaskProvider>(
          builder: (context, provider, _) {
            return ListView(
              children: [
                _sectionHeader('المظهر والبيانات'),
                
                // NEW: Dark Mode Toggle
                SwitchListTile(
                  title: const Text('الوضع الليلي (Dark Mode)'),
                  secondary: Icon(
                    provider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: const Color(0xFF1A6B4A),
                  ),
                  value: provider.isDarkMode,
                  activeColor: const Color(0xFF1A6B4A),
                  onChanged: (v) => provider.toggleDarkMode(v),
                ),

                ListTile(
                  title: const Text('رفع مهام من ملف CSV'),
                  subtitle: const Text('دعم كامل للغة العربية (UTF-8)'),
                  leading: const Icon(Icons.upload_file, color: Color(0xFF1A6B4A)),
                  onTap: () => _handleCsvUpload(context, provider),
                ),
                
                if (provider.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: LinearProgressIndicator(color: Color(0xFF1A6B4A)),
                  ),
                
                const Divider(),
                _sectionHeader('التفضيلات'),
                SwitchListTile(
                  title: const Text('بداية الأسبوع يوم السبت'),
                  value: provider.startOnSaturday,
                  activeColor: const Color(0xFF1A6B4A),
                  onChanged: (v) => provider.setStartOnSaturday(v),
                ),
                SwitchListTile(
                  title: const Text('اللغة العربية'),
                  value: provider.arabicMode,
                  activeColor: const Color(0xFF1A6B4A),
                  onChanged: (v) => provider.setArabicMode(v),
                ),
                
                const Divider(),
                _sectionHeader('عن التطبيق'),
                const ListTile(
                  title: Text('يومي - Yawmi'),
                  subtitle: Text('النسخة الاحترافية v2.3\nدعم الوضع الليلي والاستيراد'),
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
        final input = file.openRead();
        final fields = await input
            .transform(utf8.decoder) 
            .transform(const CsvToListConverter())
            .toList();

        await provider.bulkUploadTasks(fields);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم استيراد المهام العربية بنجاح'),
              backgroundColor: Color(0xFF1A6B4A),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تأكد أن الملف بتنسيق CSV (UTF-8)'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1A6B4A), 
          fontWeight: FontWeight.bold, 
          fontSize: 13
        ),
      ),
    );
  }
}