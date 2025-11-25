import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import 'task_detail_screen.dart'; // Import agar bisa diklik ke detail

class ExpandableUnfinishedTasks extends StatelessWidget {
  final List<Task> tasks;
  final Function() onRefresh; // Callback untuk refresh jika ada update

  const ExpandableUnfinishedTasks({
    Key? key, 
    required this.tasks,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Filter tugas yang belum selesai
    final unfinished = tasks.where((t) => !t.statusSelesai).toList();
    
    // Sortir berdasarkan deadline (yang paling dekat di atas)
    unfinished.sort((a, b) {
      if (a.deadline == null) return 1;
      if (b.deadline == null) return -1;
      return a.deadline!.compareTo(b.deadline!);
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // Gunakan ExpansionTile untuk fitur Minimize/Expand
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // Hilangkan garis pemisah default
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 16),
          
          // JUDUL (Header saat ditutup)
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 12),
              const Text(
                "Tugas Belum Selesai",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${unfinished.length}",
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          
          // ISI (Muncul saat diklik/expand)
          children: unfinished.isEmpty 
            ? [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Hore! Tidak ada tugas tertunda.", style: TextStyle(color: Colors.grey)),
                )
              ]
            : unfinished.map((task) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  leading: const Icon(Icons.circle_outlined, size: 16, color: Colors.grey),
                  title: Text(
                    task.judul,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: task.deadline != null 
                    ? Text(
                        DateFormat('dd MMM, HH:mm', 'id_ID').format(task.deadline!),
                        style: TextStyle(
                          fontSize: 12, 
                          color: task.deadline!.isBefore(DateTime.now()) ? Colors.red : Colors.grey
                        ),
                      )
                    : null,
                  trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                  onTap: () async {
                    // Navigasi ke Detail jika diklik
                    final bool? res = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
                    );
                    if (res == true) onRefresh();
                  },
                );
              }).toList(),
        ),
      ),
    );
  }
}