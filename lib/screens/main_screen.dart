import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart'; 
import 'starred_tasks_screen.dart'; // <--- FILE BARU (Halaman Bintang)

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

  // --- State Management Utama ---
  int _selectedIndex = 0;
  bool _isLoading = true;
  String _errorMessage = '';

  // Data Utama
  List<Task> _allTasks = [];
  List<Category> _allCategories = [];
  
  // Data Terfilter untuk Home
  List<Task> _ongoingTasks = [];
  List<Task> _overdueTasks = [];
  List<Task> _completedTasks = [];

  // Filter Logic
  TaskFilterType _currentFilterType = TaskFilterType.all;
  int? _selectedCategoryId;
  String _appBarTitle = 'Semua Tugas';

  // --- State Accordion (Buka/Tutup List di Home) ---
  bool _isKategoriExpanded = true;
  bool _isOngoingExpanded = true;
  bool _isOverdueExpanded = true;
  bool _isCompletedExpanded = false;

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

      if (mounted) {
        setState(() {
          _allTasks = results[0] as List<Task>;
          _allCategories = results[1] as List<Category>;
        });
        _filterTasks(); // Jalankan filter ulang
      }

    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. LOGIKA FILTER (HOME SCREEN) ---
  void _filterTasks() {
    if (!mounted) return;

    List<Task> tempTasks;

    setState(() {
      // Filter Awal (Kategori atau Semua)
      // Catatan: Filter 'starred' sekarang ditangani halaman terpisah,
      // jadi logic di sini fokus ke Category & All.
      switch (_currentFilterType) {
        case TaskFilterType.category:
          tempTasks = _allTasks.where((task) {
            return task.categories?.any((cat) => cat.id == _selectedCategoryId) ?? false;
          }).toList();
          
          // Ubah judul AppBar sesuai nama Kategori
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
          // Fallback jika masih terpilih starred (meski harusnya navigasi pindah)
          tempTasks = _allTasks.where((t) => t.isStarred).toList();
          _appBarTitle = 'Bintangi Tugas';
          break;
        case TaskFilterType.all:
        default:
          tempTasks = _allTasks;
          _appBarTitle = 'Semua Tugas';
      }

      // Bagi menjadi 3 Grup Status
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

  // --- 3. NAVIGASI KHUSUS HALAMAN BINTANG (BARU) ---
  void _navigateToStarredPage() {
    // Navigasi Push ke halaman baru
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StarredTasksScreen(
          allTasks: _allTasks, 
          onUpdateTask: _handleTaskUpdate, // Bisa update status dari halaman bintang
          onRefreshData: _loadData, // Bisa refresh data utama
        ),
      ),
    ).then((_) {
      // Saat kembali dari halaman bintang, refresh data untuk sinkronisasi
      _loadData();
    });
  }

  // --- 4. CALLBACK DARI DRAWER (FILTER BIASA) ---
  void _onFilterSelected(TaskFilterType type, {int? categoryId}) {
    setState(() {
      _currentFilterType = type;
      _selectedCategoryId = categoryId;
      _selectedIndex = 0; // Balik ke tab Home
    });
    _filterTasks();
    
    // HAPUS Navigator.pop disini karena AppDrawer sudah handle pop
    // untuk mencegah layar hitam (Double Pop).
  }

  // --- 5. UPDATE DATA (Global) ---
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

  // --- 6. POP-UP TAMBAH TUGAS (ADD TASK SHEET) ---
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
          onCreateCategory: (name) async {
             try {
                await _apiService.createCategory(name);
                final newCats = await _apiService.getCategories();
                setState(() => _allCategories = newCats);
             } catch (e) {
                _showError(e.toString());
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

  // Dialog Tambah Kategori (Drawer)
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

  // Navigasi Bottom Bar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Toggle State Accordion
  void _toggleKategori(bool isExpanded) => setState(() { _isKategoriExpanded = isExpanded; });
  void _toggleOngoing(bool isExpanded) => setState(() { _isOngoingExpanded = isExpanded; });
  void _toggleOverdue(bool isExpanded) => setState(() { _isOverdueExpanded = isExpanded; });
  void _toggleCompleted(bool isExpanded) => setState(() { _isCompletedExpanded = isExpanded; });

  // --- 7. BUILD UTAMA ---
  @override
  Widget build(BuildContext context) {
    
    final List<Widget> widgetOptions = <Widget>[
      
      // A. HOME SCREEN (Index 0)
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
                  // State Accordion
                  isOngoingExpanded: _isOngoingExpanded,
                  isOverdueExpanded: _isOverdueExpanded,
                  isCompletedExpanded: _isCompletedExpanded,
                  onOngoingToggled: _toggleOngoing,
                  onOverdueToggled: _toggleOverdue,
                  onCompletedToggled: _toggleCompleted,
                ),

      // B. CALENDAR SCREEN (Index 1)
      CalendarScreen(
        tasks: _allTasks, // Data dikirim supaya kalender ada isinya
        onTaskUpdate: (_) => _loadData(),
      ),

      // C. PROFILE SCREEN (Index 2)
      // Tanpa parameter, sesuai kode temanmu
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
          // Refresh button hanya di Home
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
        
        // PENTING: Callback untuk buka halaman bintang
        onOpenStarredPage: _navigateToStarredPage, 
      ),

      body: widgetOptions.elementAt(_selectedIndex),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskSheet,
        tooltip: 'Tambah Tugas',
        backgroundColor: Colors.purple[100], 
        child: const Icon(Icons.add, color: Colors.purple),
      ),

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