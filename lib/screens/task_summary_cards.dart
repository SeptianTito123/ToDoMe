import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskSummaryCards extends StatelessWidget {
  final List<Task> tasks; // Menerima data

  const TaskSummaryCards({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    // Hitung data real
    final int completed = tasks.where((t) => t.statusSelesai).length;
    final int pending = tasks.where((t) => !t.statusSelesai).length;

    return Row(
      children: [
        _buildCard(completed.toString(), "Tugas Selesai", Colors.blue[100]!),
        const SizedBox(width: 12),
        _buildCard(pending.toString(), "Tugas Tertunda", Colors.red[100]!),
      ],
    );
  }

  Widget _buildCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
}