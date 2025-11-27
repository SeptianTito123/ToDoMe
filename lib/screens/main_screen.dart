import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart'; 
import 'starred_tasks_screen.dart'; 

import '../models/task.dart';
import '../models/category.dart';
import '../models/subtask.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart'; 
import '../widgets/add_task_sheet.dart'; 

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ApiService _apiService = ApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _categoryController = TextEditingController();

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

  bool _isKategoriExpanded = true;
  bool _isOngoingExpanded = true;
  bool _isOverdueExpanded = true;
  bool _isCompletedExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

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

      if (mounted) {
        setState(() {
          _allTasks = results[0] as List<Task>;
          _allCategories = results[1] as List<Category>;
        });
        _filterTasks();
      }

    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterTasks() {
    if (!mounted) return;

    List<Task> tempTasks;

    setState(() {
      switch (_currentFilterType) {
        case TaskFilterType.category:
          tempTasks = _allTasks.where((task) {
            return task.categories?.any((cat) => cat.id == _selectedCategoryId) ?? false;
          }).toList();
          
          if (_selectedCategoryId != null && _allCategories.isNotEmpty) {
             try {
               final cat = _allCategories.firstWhere((c) => c.id == _selectedCategoryId);
               _appBarTitle = cat.name;
             } catch (_) {
               _appBarTitle = 'Kategori';
             }
          }
          break;
        case TaskFilterType.starred:
          tempTasks = _allTasks.where((t) => t.isStarred).toList();
          _appBarTitle = 'Bintangi Tugas';
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

  void _navigateToStarredPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StarredTasksScreen(
          allTasks: _allTasks, 
          onUpdateTask: _handleTaskUpdate,
          onRefreshData: _loadData,
        ),
      ),
    ).then((_) {
      _loadData();
    });
  }

  void _onFilterSelected(TaskFilterType type, {int? categoryId}) {
    setState(() {
      _currentFilterType = type;
      _selectedCategoryId = categoryId;
      _selectedIndex = 0;
    });
    _filterTasks();
  }

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
      _showError("Gagal update: $e");
    }
  }

  // --- POP-UP TAMBAH TUGAS (ADD TASK SHEET) ---
  void _showAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent, 
      builder: (_) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: AddTaskSheet(
          categories: _allCategories,
          // PERBAIKAN: onCreateCategory sekarang return Category object
          onCreateCategory: (name) async {
             try {
               final newCat = await _apiService.createCategory(name);
               
               // Update list global di MainScreen juga
               final newCats = await _apiService.getCategories();
               setState(() => _allCategories = newCats);
               
               // Kembalikan kategori baru ke Sheet agar bisa ditampilkan
               return newCat;
             } catch (e) {
               _showError(e.toString());
               return null;
             }
          },
          onSave: (judul, deskripsi, deadline, catIds, subtasks) async {
             try {
               await _apiService.createTask(
                 judul: judul, 
                 deskripsi: deskripsi, 
                 deadline: deadline, 
                 categoryIds: catIds,
                 subtasks: subtasks 
               );
               _loadData(); 
             } catch (e) {
               _showError(e.toString());
             }
          },
        ),
      ),
    );
  }

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
                  Navigator.pop(context);
                  _loadData();
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleKategori(bool isExpanded) => setState(() { _isKategoriExpanded = isExpanded; });
  void _toggleOngoing(bool isExpanded) => setState(() { _isOngoingExpanded = isExpanded; });
  void _toggleOverdue(bool isExpanded) => setState(() { _isOverdueExpanded = isExpanded; });
  void _toggleCompleted(bool isExpanded) => setState(() { _isCompletedExpanded = isExpanded; });

  @override
  Widget build(BuildContext context) {
    
    final List<Widget> widgetOptions = <Widget>[
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
                  isOngoingExpanded: _isOngoingExpanded,
                  isOverdueExpanded: _isOverdueExpanded,
                  isCompletedExpanded: _isCompletedExpanded,
                  onOngoingToggled: _toggleOngoing,
                  onOverdueToggled: _toggleOverdue,
                  onCompletedToggled: _toggleCompleted,
                ),

      CalendarScreen(
        tasks: _allTasks, 
        onTaskUpdate: (_) => _loadData(),
      ),

      const ProfileScreen(), 
    ];

    return Scaffold(
      key: _scaffoldKey,

      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? _appBarTitle 
          : (_selectedIndex == 1 ? 'Kalender' : 'Profil')
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          if (_selectedIndex == 0)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData)
        ],
      ),

      drawer: AppDrawer(
        categories: _allCategories,
        allTasksCount: _allTasks.length,
        starredTasksCount: _allTasks.where((t) => t.isStarred).length,
        onFilterSelected: _onFilterSelected,
        onAddCategory: _showAddCategoryDialog,
        isKategoriExpanded: _isKategoriExpanded,
        onKategoriToggled: _toggleKategori,
        onOpenStarredPage: _navigateToStarredPage, 
        
        onDeleteCategory: (category) async {
          try {
            await _apiService.deleteCategory(category.id);
            if (_selectedCategoryId == category.id) {
              setState(() {
                _currentFilterType = TaskFilterType.all;
                _selectedCategoryId = null;
                _selectedIndex = 0;
              });
            }
            _loadData();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Kategori '${category.name}' dihapus")),
            );
          } catch (e) {
            _showError("Gagal menghapus: $e");
          }
        },
      ),

      body: widgetOptions.elementAt(_selectedIndex),

      floatingActionButton: _selectedIndex == 0 
          ? FloatingActionButton(
              onPressed: _showAddTaskSheet,
              tooltip: 'Tambah Tugas',
              backgroundColor: Colors.purple[100], 
              child: const Icon(Icons.add, color: Colors.purple),
            )
          : null,

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Tugas',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Kalender',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}