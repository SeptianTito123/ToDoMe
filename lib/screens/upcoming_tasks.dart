import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class UpcomingTasks extends StatelessWidget {
  final List<Task> tasks;

  const UpcomingTasks({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    // Cari tugas: Belum selesai, Punya deadline, dan Deadline di masa depan
    final now = DateTime.now();
    final upcomingList = tasks.where((t) => 
      !t.statusSelesai && 
      t.deadline != null && 
      t.deadline!.isAfter(now)
    ).toList();

    // Urutkan dari deadline terdekat
    upcomingList.sort((a, b) => a.deadline!.compareTo(b.deadline!));

    // Ambil yang paling dekat (index 0), atau null jika kosong
    final Task? nextTask = upcomingList.isNotEmpty ? upcomingList.first : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.purple), // Sesuaikan tema
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nextTask != null ? nextTask.judul : "Tidak ada tugas mendatang",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                if (nextTask != null)
                  Text(
                    DateFormat('EEEE, d MMM HH:mm', 'id_ID').format(nextTask.deadline!),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          if (nextTask != null)
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
               decoration: BoxDecoration(
                 color: Colors.purple[50],
                 borderRadius: BorderRadius.circular(8)
               ),
               child: Text(
                 DateFormat('d MMM').format(nextTask.deadline!),
                 style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
               ),
             ),
        ],
      ),
    );
  }
}