import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';

class AddTaskSheet extends StatefulWidget {
  final List<Category> categories;
  // Callback onSave sekarang menerima subtasks juga
  final Function(String judul, String deskripsi, DateTime? deadline, List<int> catIds, List<String> subtasks) onSave;
  final Function(String) onCreateCategory;

  const AddTaskSheet({
    Key? key, 
    required this.categories, 
    required this.onSave, 
    required this.onCreateCategory
  }) : super(key: key);

  @override
  _AddTaskSheetState createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _subtaskController = TextEditingController();
  
  DateTime? _selectedDate;
  List<int> _selectedCategoryIds = [];
  List<String> _subtasks = []; // Menyimpan list subtask sementara

  // --- LOGIKA TANGGAL & WAKTU ---
  void _setDate(int daysToAdd) {
    final now = DateTime.now();
    setState(() {
      if (daysToAdd == 0) {
        // HARI INI: Set ke jam 23:59:59 (Akhir Hari)
        _selectedDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (daysToAdd == 1) {
        // BESOK: Set ke jam 23:59:59 juga (Biasanya deadline itu akhir hari)
        final tmr = now.add(const Duration(days: 1));
        _selectedDate = DateTime(tmr.year, tmr.month, tmr.day, 23, 59, 59);
      }
    });
  }

  // Pilih Tanggal & Jam Custom (Mirip add_task_screen)
  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    // 1. Pilih Tanggal
    final pickedDate = await showDatePicker(
      context: context, 
      initialDate: _selectedDate ?? now, 
      firstDate: now, 
      lastDate: DateTime(2100)
    );
    
    if (pickedDate != null) {
      // 2. Pilih Jam (Langsung muncul setelah pilih tanggal agar praktis)
      if (!mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate ?? now),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year, pickedDate.month, pickedDate.day,
            pickedTime.hour, pickedTime.minute
          );
        });
      }
    }
  }

  // --- LOGIKA SUBTASK ---
  void _addSubtask() {
    if (_subtaskController.text.isNotEmpty) {
      setState(() {
        _subtasks.add(_subtaskController.text);
        _subtaskController.clear();
      });
    }
  }

  void _removeSubtask(int index) {
    setState(() {
      _subtasks.removeAt(index);
    });
  }

  // --- LOGIKA KATEGORI ---
  void _showAddCategoryDialog() {
    final catController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Kategori Baru"),
        content: TextField(controller: catController, decoration: const InputDecoration(hintText: "Nama Kategori")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(onPressed: () {
            if (catController.text.isNotEmpty) {
              widget.onCreateCategory(catController.text);
              Navigator.pop(ctx);
            }
          }, child: const Text("Simpan"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Menggunakan DraggableScrollableSheet atau SingleChildScrollView agar bisa scroll
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom, // Menghindari Keyboard
        left: 16, right: 16, top: 12
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
           // Handle Bar (Garis kecil di atas)
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),

          // AREA SCROLLABLE (Agar muat banyak konten)
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. JUDUL
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: "Apa yang ingin dikerjakan?", 
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)
                    ),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    autofocus: true, 
                  ),
                  
                  // 2. DESKRIPSI
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      hintText: "Deskripsi (opsional)", 
                      border: InputBorder.none, 
                      icon: Icon(Icons.description_outlined, size: 20, color: Colors.grey)
                    ),
                    style: const TextStyle(fontSize: 14),
                    maxLines: 3,
                    minLines: 1,
                  ),
                  const Divider(),

                  // 3. SUBTASKS (Baru ditambahkan)
                  if (_subtasks.isNotEmpty) ...[
                    const Text('Sub-tugas:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _subtasks.length,
                      itemBuilder: (ctx, index) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.check_box_outline_blank, size: 18),
                        title: Text(_subtasks[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.red),
                          onPressed: () => _removeSubtask(index),
                        ),
                      ),
                    ),
                  ],
                  // Input Subtask Baru
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subtaskController,
                          decoration: const InputDecoration(
                            hintText: "Tambah item checklist...",
                            border: InputBorder.none,
                            icon: Icon(Icons.checklist, size: 20, color: Colors.grey),
                          ),
                          style: const TextStyle(fontSize: 14),
                          onSubmitted: (_) => _addSubtask(), // Tekan enter untuk tambah
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.blue),
                        onPressed: _addSubtask,
                      )
                    ],
                  ),
                  const Divider(),

                  // 4. KATEGORI
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.blue), 
                          onPressed: _showAddCategoryDialog,
                        ),
                        ...widget.categories.map((cat) {
                          final isSelected = _selectedCategoryIds.contains(cat.id);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(cat.name),
                              selected: isSelected,
                              selectedColor: Colors.blue[100],
                              onSelected: (val) {
                                setState(() {
                                  val ? _selectedCategoryIds.add(cat.id) : _selectedCategoryIds.remove(cat.id);
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 5. TANGGAL & WAKTU (Shortcut + Custom)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildDateChip("Hari Ini", Icons.today, 0),
                        const SizedBox(width: 8),
                        _buildDateChip("Besok", Icons.wb_sunny_outlined, 1),
                        const SizedBox(width: 8),
                        ActionChip(
                          label: Text(_selectedDate == null 
                            ? "Pilih Waktu" 
                            : DateFormat("dd MMM, HH:mm").format(_selectedDate!)
                          ),
                          avatar: const Icon(Icons.calendar_month, size: 16),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey.shade300),
                          onPressed: _pickCustomDate,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // 6. TOMBOL SIMPAN (Sticky di bawah)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14)
              ),
              onPressed: () {
                if (_titleController.text.isNotEmpty) {
                  widget.onSave(
                    _titleController.text, 
                    _descController.text, 
                    _selectedDate, 
                    _selectedCategoryIds,
                    _subtasks, // <-- Kirim subtasks ke parent
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text("Simpan Tugas", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDateChip(String label, IconData icon, int days) {
    bool isSelected = false;
    if (_selectedDate != null) {
      final now = DateTime.now();
      final target = days == 0 ? now : now.add(const Duration(days: 1));
      isSelected = _selectedDate!.day == target.day && _selectedDate!.month == target.month;
    }

    return ActionChip(
      label: Text(label),
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
      backgroundColor: isSelected ? Colors.blue : Colors.white,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      side: BorderSide(color: isSelected ? Colors.blue : Colors.grey.shade300),
      onPressed: () => _setDate(days),
    );
  }
}