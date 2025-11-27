import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import '../screens/task_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task)? onTaskUpdate; 

  const CalendarScreen({
    Key? key, 
    required this.tasks, 
    this.onTaskUpdate
  }) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Task> _selectedTasks = [];
  
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedTasks = _getTasksForDay(_focusedDay);
  }

  List<Task> _getTasksForDay(DateTime day) {
    return widget.tasks.where((task) {
      if (task.deadline == null) return false;
      return isSameDay(task.deadline, day);
    }).toList();
  }

  @override
  void didUpdateWidget(covariant CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedDay != null) {
      _selectedTasks = _getTasksForDay(_selectedDay!);
    }
  }

  // --- FUNGSI UPDATE TUGAS (Checklist & Bintang) ---
  Future<void> _updateTaskLocally(Task task, Map<String, dynamic> data) async {
    try {
      // 1. Panggil API untuk update di server
      final updatedTask = await _apiService.updateTask(task.id, data);

      // 2. Update UI Lokal (List di Kalender) agar langsung berubah
      setState(() {
        final index = _selectedTasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _selectedTasks[index] = updatedTask;
        }
      });

      // 3. Kabari Parent (MainScreen) agar list utama di Home juga terupdate
      if (widget.onTaskUpdate != null) {
        widget.onTaskUpdate!(updatedTask);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar dihapus atau disesuaikan jika ingin header custom
      // (Di MainScreen sudah ada AppBar global, tapi CalendarScreen ini sering pakai body saja)
      // Namun jika Anda ingin AppBar spesifik di dalam Calendar:
      // appBar: AppBar(...) 
      // Kita gunakan Column langsung karena MainScreen sudah punya Scaffold & AppBar
      
      body: Column(
        children: [
          // --- 1. WIDGET KALENDER ---
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.5), 
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.purple, 
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedTasks = _getTasksForDay(selectedDay);
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: _getTasksForDay,
            ),
          ),

          const SizedBox(height: 16),
          
          // --- 2. HEADER LIST ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Text(
                  _selectedDay == null 
                      ? "Tugas" 
                      : DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDay!),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const Spacer(),
                Text(
                  "${_selectedTasks.length} Tugas",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10),

          // --- 3. LIST TUGAS HARIAN ---
          Expanded(
            child: _selectedTasks.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _selectedTasks.length,
                  itemBuilder: (context, index) {
                    final task = _selectedTasks[index];
                    return _buildTaskItem(task);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            "Tidak ada deadline hari ini",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    return Card(
      elevation: 0,
      color: Colors.blue[50],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        // CHECKBOX: Panggil _updateTaskLocally saat diklik
        leading: Checkbox(
          value: task.statusSelesai,
          activeColor: Colors.purple,
          onChanged: (val) {
            if (val != null) {
              _updateTaskLocally(task, {'status_selesai': val});
            }
          },
        ),
        title: Text(
          task.judul,
          style: TextStyle(
            decoration: task.statusSelesai ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          task.deadline != null 
            ? DateFormat('HH:mm').format(task.deadline!)
            : '-',
          style: TextStyle(color: Colors.grey[600]),
        ),
        // ICON BINTANG: Panggil _updateTaskLocally saat diklik
        trailing: GestureDetector(
          onTap: () {
            _updateTaskLocally(task, {'is_starred': !task.isStarred});
          },
          child: Icon(
            task.isStarred ? Icons.star : Icons.star_border,
            color: task.isStarred ? Colors.amber : Colors.grey,
          ),
        ),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
          );
          
          // Jika user mengedit di halaman detail, refresh list
          if (result == true) {
             setState(() {
               _selectedTasks = _getTasksForDay(_selectedDay!);
             });
             // Trigger parent refresh juga
             if (widget.onTaskUpdate != null) {
                // Kita panggil dengan task yang ada (atau dummy), tujuannya agar parent reloadAll
                widget.onTaskUpdate!(task);
             }
          }
        },
      ),
    );
  }
}