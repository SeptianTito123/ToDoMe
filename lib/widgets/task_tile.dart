import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../utils/time_helper.dart'; 

class TaskTile extends StatelessWidget {
  final Task task;
  final Function(bool?) onStatusChanged;
  final VoidCallback onStarToggled;
  final VoidCallback onTap;

  const TaskTile({
    Key? key,
    required this.task,
    required this.onStatusChanged,
    required this.onStarToggled,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Menggunakan Helper Baru: getTaskStatusText(task)
    // Agar bisa mendeteksi "Selesai terlambat" vs "Selesai tepat waktu"
    String statusText = "";
    try {
       statusText = TimeHelper.getTaskStatusText(task);
    } catch (e) {
       // Fallback jika error
       statusText = task.deadline != null 
        ? DateFormat('dd MMM HH:mm').format(task.deadline!) 
        : "";
    }

    // 2. Tentukan Warna Teks
    Color statusColor = Colors.grey[600]!;
    if (statusText.contains('Terlambat')) {
      statusColor = Colors.red;
    } else if (statusText.contains('Selesai')) {
      statusColor = Colors.green;
    }

    return Opacity(
      opacity: task.statusSelesai ? 0.6 : 1.0,
      child: Card(
        elevation: 0,
        color: Colors.blue[50], 
        margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: task.statusSelesai,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              activeColor: Colors.purple,
              onChanged: onStatusChanged,
            ),
          ),
          title: Text(
            task.judul,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              decoration: task.statusSelesai
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
          ),
          subtitle: statusText.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: task.statusSelesai ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                )
              : null,
          trailing: IconButton(
            icon: Icon(
              task.isStarred ? Icons.star : Icons.star_border,
              color: task.isStarred ? Colors.amber : Colors.grey,
              size: 28,
            ),
            onPressed: onStarToggled,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}