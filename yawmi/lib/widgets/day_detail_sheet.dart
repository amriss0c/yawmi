// lib/widgets/day_detail_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for Haptics
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20, left: 20, right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('تفاصيل المهمة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'ماذا تود أن تنجز اليوم؟',
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1A6B4A))),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statusButton(1, 'منجزة', Colors.green),
              _statusButton(0, 'غير منجزة', Colors.red),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A6B4A),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: () {
                // HIGH-END UX: Medium physical vibration on save
                HapticFeedback.mediumImpact(); 
                
                context.read<TaskProvider>().updateTask(
                  widget.date,
                  _controller.text,
                  _status,
                );
                Navigator.pop(context);
              },
              child: const Text('حفظ', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusButton(int value, String label, Color color) {
    bool isSelected = _status == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          // LIGHT UX: Selection tap vibration
          HapticFeedback.selectionClick(); 
          setState(() => _status = value);
        }
      },
      selectedColor: color.withOpacity(0.3),
    );
  }
}