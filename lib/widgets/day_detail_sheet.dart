import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../utils/hijri_helper.dart';

class DayDetailSheet extends StatefulWidget {
  final DateTime date;
  const DayDetailSheet({super.key, required this.date});

  @override
  State<DayDetailSheet> createState() => _DayDetailSheetState();
}

class _DayDetailSheetState extends State<DayDetailSheet> {
  late TextEditingController _controller;
  int _status = 0;

  @override
  void initState() {
    super.initState();
    final task = context.read<TaskProvider>().getTask(widget.date);
    _controller = TextEditingController(text: task?.taskText ?? '');
    _status = task?.status ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(HijriHelper.getFullHijriDate(widget.date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 15),
          TextField(controller: _controller, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'المهمة...')),
          SwitchListTile(title: const Text('تم الإنجاز'), value: _status == 1, onChanged: (v) => setState(() => _status = v ? 1 : 0)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A6B4A), minimumSize: const Size(double.infinity, 50)),
            onPressed: () {
              context.read<TaskProvider>().updateTask(widget.date, _controller.text, _status);
              Navigator.pop(context);
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}