import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:todome/models/category.dart';
import 'package:todome/services/api_service.dart';

class AddTaskScreen extends StatefulWidget {
  final VoidCallback onTaskAdded; 
  
  const AddTaskScreen({Key? key, required this.onTaskAdded}) : super(key: key);

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _subtaskController = TextEditingController();
  
  bool _isLoading = false;
  bool _isDataDirty = false; // <-- 1. TAMBAHKAN FLAG "DIRTY"
  List<String> _subtasks = []; 
  List<Category> _allCategories = []; 
  List<int> _selectedCategoryIds = [];
  DateTime? _selectedDate; 

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _apiService.getCategories();
      setState(() {
        _allCategories = categories;
      });
    } catch (e) {
      _showError("Gagal memuat kategori: $e");
    }
  }

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

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context, initialDate: _selectedDate ?? now,
      firstDate: now, lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        final existingTime = _selectedDate;
        _selectedDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
                                  existingTime?.hour ?? 0, existingTime?.minute ?? 0);
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final now = DateTime.now();
    final pickedTime = await showTimePicker(
      context: context, initialTime: TimeOfDay.fromDateTime(_selectedDate ?? now),
    );
    if (pickedTime != null) {
      setState(() {
        final existingDate = _selectedDate ?? now;
        _selectedDate = DateTime(existingDate.year, existingDate.month, existingDate.day,
                                  pickedTime.hour, pickedTime.minute);
      });
    }
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog( 
        title: const Text('Kategori Baru'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama Kategori'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              try {
                await _apiService.createCategory(controller.text);
                Navigator.pop(dialogContext); 
                _loadCategories(); // Tetap refresh chip lokal
                // --- 2. SET FLAG "DIRTY" ---
                setState(() {
                  _isDataDirty = true;
                });
                // --- BATAS REVISI ---
              } catch (e) {
                _showError("Gagal: $e");
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) {
      return; 
    }
    setState(() { _isLoading = true; });
    try {
      await _apiService.createTask(
        judul: _judulController.text,
        deskripsi: _deskripsiController.text.isNotEmpty ? _deskripsiController.text : null,
        deadline: _selectedDate,
        categoryIds: _selectedCategoryIds.isNotEmpty ? _selectedCategoryIds : null,
        subtasks: _subtasks.isNotEmpty ? _subtasks : null,
      );
      
      widget.onTaskAdded(); // Ini sudah memanggil _loadData di MainScreen
      Navigator.of(context).pop(false); // Pop, tapi kirim 'false' (tidak dirty)
      
    } catch (e) {
      _showError("Gagal menyimpan tugas: $e");
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- 3. BUNGKUS DENGAN WILLPOPSCOPE ---
    return WillPopScope(
      onWillPop: () async {
        // Saat tombol 'back' HP ditekan, kirim status 'dirty'
        Navigator.pop(context, _isDataDirty);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          // Modifikasi tombol 'back' di AppBar
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _isDataDirty),
          ),
          title: const Text('Tugas Baru'),
          actions: [
            _isLoading
                ? const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: Colors.white))
                : IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: _submitTask,
                  )
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // (Sisa UI biarkan sama persis)
                TextFormField(
                  controller: _judulController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Tugas',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Judul tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _deskripsiController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                
                const Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8.0,
                  children: _allCategories.map((category) {
                    final isSelected = _selectedCategoryIds.contains(category.id);
                    return FilterChip(
                      label: Text(category.name),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategoryIds.add(category.id);
                          } else {
                            _selectedCategoryIds.remove(category.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  leading: const Icon(Icons.add, color: Colors.green),
                  title: const Text('Tambah Kategori Baru', style: TextStyle(color: Colors.green)),
                  onTap: _showAddCategoryDialog,
                ),
                const Divider(height: 24),
                
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(_selectedDate == null
                      ? 'Atur Tanggal' 
                      : 'Tanggal: ${DateFormat('dd MMM yyyy').format(_selectedDate!.toLocal())}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickDate(context), 
                ),
                ListTile(
                  leading: const Icon(Icons.access_time_outlined),
                  title: Text(_selectedDate == null
                      ? 'Atur Jam' 
                      : 'Jam: ${DateFormat('HH:mm').format(_selectedDate!.toLocal())}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickTime(context), 
                ),
                const Divider(height: 24),
                
                const Text('Checklist Sub-tugas', style: TextStyle(fontWeight: FontWeight.bold)),
                
                ..._subtasks.asMap().entries.map((entry) {
                  int index = entry.key;
                  String title = entry.value;
                  return ListTile(
                    leading: const Icon(Icons.check_box_outline_blank),
                    title: Text(title),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeSubtask(index),
                    ),
                  );
                }),
                
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subtaskController,
                        decoration: const InputDecoration(
                          labelText: 'Item checklist baru...',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.green),
                      onPressed: _addSubtask,
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}