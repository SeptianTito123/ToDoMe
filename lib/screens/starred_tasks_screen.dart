import 'package:flutter/material.dart';
import '../models/task.dart';
import '../widgets/task_tile.dart'; 
import 'task_detail_screen.dart';

class StarredTasksScreen extends StatefulWidget {
  final List<Task> allTasks;
  final Function(Task, Map<String, dynamic>) onUpdateTask;
  final VoidCallback onRefreshData; // Callback untuk refresh data utama

  const StarredTasksScreen({
    Key? key,
    required this.allTasks,
    required this.onUpdateTask,
    required this.onRefreshData,
  }) : super(key: key);

  @override
  State<StarredTasksScreen> createState() => _StarredTasksScreenState();
}

class _StarredTasksScreenState extends State<StarredTasksScreen> {
  @override
  Widget build(BuildContext context) {
    // Filter tugas yang berbintang saja
    final starredTasks = widget.allTasks.where((t) => t.isStarred).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bintangi Tugas"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      body: starredTasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    "Belum ada tugas berbintang",
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: starredTasks.length,
              itemBuilder: (context, index) {
                final task = starredTasks[index];
                
                // Gunakan TaskTile agar tampilan konsisten
                return TaskTile(
                  task: task,
                  onStatusChanged: (val) {
                    if (val == null) return;
                    widget.onUpdateTask(task, {'status_selesai': val});
                    setState(() {}); // Refresh tampilan lokal
                  },
                  onStarToggled: () {
                    // Saat bintang dicabut, item akan hilang dari list ini
                    widget.onUpdateTask(task, {'is_starred': !task.isStarred});
                    setState(() {}); 
                  },
                  onTap: () async {
                    bool? res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailScreen(task: task),
                      ),
                    );
                    if (res == true) {
                      widget.onRefreshData(); // Refresh data dari server jika ada edit detail
                      setState(() {});
                    }
                  },
                );
              },
            ),
    );
  }
}