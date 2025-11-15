import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../models/subtask.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart'; // Impor ini sudah mengandung TaskFilterType
import 'add_task_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ApiService _apiService = ApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _categoryController = TextEditingController();

  // --- State Management Utama ---
  int _selectedIndex = 0;
  bool _isLoading = true;
  String _errorMessage = '';

  List<Task> _allTasks = [];
  List<Category> _allCategories = [];
  List<Task> _ongoingTasks = [];
  List<Task> _overdueTasks = [];
  List<Task> _completedTasks = [];

  TaskFilterType _currentFilterType = TaskFilterType.all;
  int? _selectedCategoryId;
  String _appBarTitle = 'Semua Tugas';

  // --- STATE BARU: Untuk Mengingat Buka/Tutup ---
  bool _isKategoriExpanded = true;
  bool _isOngoingExpanded = true;
  bool _isOverdueExpanded = true;
  bool _isCompletedExpanded = false;
  // --- BATAS STATE BARU ---

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- 1. MEMUAT DATA ---
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await Future.wait([
        _apiService.getTasks(),
        _apiService.getCategories(),
      ]);

      _allTasks = results[0] as List<Task>;
      _allCategories = results[1] as List<Category>;

      _filterTasks();

    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. LOGIKA FILTER ---
  void _filterTasks() {
    if (!mounted) return;

    List<Task> tempTasks;

    setState(() {
      switch (_currentFilterType) {
        case TaskFilterType.starred:
          tempTasks = _allTasks.where((t) => t.isStarred).toList();
          _appBarTitle = 'Bintangi Tugas';
          break;
        case TaskFilterType.category:
          tempTasks = _allTasks.where((task) {
            return task.categories?.any((cat) => cat.id == _selectedCategoryId) ?? false;
          }).toList();
          _appBarTitle = _allCategories.firstWhere((c) => c.id == _selectedCategoryId).name;
          break;
        case TaskFilterType.all:
        default:
          tempTasks = _allTasks;
          _appBarTitle = 'Semua Tugas';
      }

      final now = DateTime.now();
      List<Task> ongoing = [];
      List<Task> overdue = [];
      List<Task> completed = [];

      for (var task in tempTasks) {
        if (task.statusSelesai) {
          completed.add(task);
        } else if (task.deadline != null && task.deadline!.isBefore(now)) {
          overdue.add(task);
        } else {
          ongoing.add(task);
        }
      }

      _ongoingTasks = ongoing;
      _overdueTasks = overdue;
      _completedTasks = completed..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
  }

  // --- 3. CALLBACK DARI DRAWER ---
  void _onFilterSelected(TaskFilterType type, {int? categoryId}) {
    setState(() {
      _currentFilterType = type;
      _selectedCategoryId = categoryId;
    });
    _filterTasks();
  }

  // --- 4. CALLBACK DARI HOME ---
  Future<void> _handleTaskUpdate(Task task, Map<String, dynamic> data) async {
    try {
      final updatedTask = await _apiService.updateTask(task.id, data);
      setState(() {
        final index = _allTasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _allTasks[index] = updatedTask;
        }
      });
      _filterTasks();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _handleSubtaskUpdate(Subtask subtask, bool isCompleted) async {
    try {
      final updatedSubtask = await _apiService.updateSubtask(subtask.id, isCompleted);
      setState(() {
        final taskIndex = _allTasks.indexWhere((t) => t.id == updatedSubtask.taskId);
        if (taskIndex == -1) return;
        final subtaskList = _allTasks[taskIndex].subtasks;
        if (subtaskList == null) return;
        final subtaskIndex = subtaskList.indexWhere((s) => s.id == updatedSubtask.id);
        if (subtaskIndex == -1) return;
        _allTasks[taskIndex].subtasks![subtaskIndex] = updatedSubtask;
      });
    } catch (e) {
      _showError(e.toString());
    }
  }

  // --- 5. LOGIKA UI (DIALOG) ---
  void _showAddCategoryDialog() {
    _categoryController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Buat Kategori Baru'),
          content: TextField(
            controller: _categoryController,
            decoration: const InputDecoration(labelText: 'Nama Kategori'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_categoryController.text.isEmpty) return;
                try {
                  await _apiService.createCategory(_categoryController.text);
                  _loadData();
                  Navigator.pop(context);
                } catch (e) {
                  _showError(e.toString());
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // --- 6. NAVIGASI TAB ---
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- 7. CALLBACK BARU UNTUK BUKA/TUTUP ---
  void _toggleKategori(bool isExpanded) {
    setState(() { _isKategoriExpanded = isExpanded; });
  }
  void _toggleOngoing(bool isExpanded) {
    setState(() { _isOngoingExpanded = isExpanded; });
  }
  void _toggleOverdue(bool isExpanded) {
    setState(() { _isOverdueExpanded = isExpanded; });
  }
  void _toggleCompleted(bool isExpanded) {
    setState(() { _isCompletedExpanded = isExpanded; });
  }

  // --- 8. WIDGET BUILD (UTAMA) ---
  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      // Halaman HOME (indeks 0)
      _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : HomeScreen(
                  ongoingTasks: _ongoingTasks,
                  overdueTasks: _overdueTasks,
                  completedTasks: _completedTasks,

                  onRefresh: _loadData,
                  categories: _allCategories,
                  currentFilterType: _currentFilterType,
                  selectedCategoryId: _selectedCategoryId,
                  onFilterSelected: _onFilterSelected,
                  onUpdateTask: _handleTaskUpdate,

                  // --- KIRIM STATE & CALLBACK BARU ---
                  isOngoingExpanded: _isOngoingExpanded,
                  isOverdueExpanded: _isOverdueExpanded,
                  isCompletedExpanded: _isCompletedExpanded,
                  onOngoingToggled: _toggleOngoing,
                  onOverdueToggled: _toggleOverdue,
                  onCompletedToggled: _toggleCompleted,
                ),
      // Halaman KALENDER (indeks 1)
      const CalendarScreen(),
      // Halaman PROFIL (indeks 2)
      const ProfileScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,

      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? _appBarTitle : (_selectedIndex == 1 ? 'Kalender' : 'Profil')),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),

      // Drawer (Sidebar)
      drawer: AppDrawer(
        categories: _allCategories,
        allTasksCount: _allTasks.length,
        starredTasksCount: _allTasks.where((t) => t.isStarred).length,
        onFilterSelected: _onFilterSelected,
        onAddCategory: _showAddCategoryDialog,

        // --- KIRIM STATE & CALLBACK BARU ---
        isKategoriExpanded: _isKategoriExpanded,
        onKategoriToggled: _toggleKategori,
      ),

      body: widgetOptions.elementAt(_selectedIndex),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final bool? dataDiperbarui = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTaskScreen(
                onTaskAdded: _loadData,
              ),
            ),
          );

          if (dataDiperbarui == true) {
            _loadData();
          }
        },
        tooltip: 'Tambah Tugas',
        child: const Icon(Icons.add),
      ),

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Tugas'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Kalender'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}