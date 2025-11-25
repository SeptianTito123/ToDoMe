import 'package:flutter/material.dart';

import 'task_summary_cards.dart';
import 'weekly_line_chart.dart';          
import 'expandable_unfinished_tasks.dart'; 
import 'unfinished_pie_chart.dart';
import 'edit_profile_screen.dart'; 

import '../models/task.dart';
import '../services/google_auth_service.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- STATE VARIABEL ---
  String userName = "";
  String userBio = "";
  String userPhoto = "";
  bool loadingProfile = true;
  
  List<Task> _tasks = []; // Data tugas untuk grafik & list
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadAllData(); // Load semua data saat halaman dibuka
  }

  // --- 1. FUNGSI LOAD DATA (PARALEL) ---
  Future<void> _loadAllData() async {
    setState(() => loadingProfile = true);
    try {
      // Jalankan getProfile dan getTasks secara bersamaan agar cepat
      await Future.wait([
        _loadProfile(),
        _loadTasks(),
      ]);
    } catch (e) {
      print("Error loading data: $e");
    } finally {
      if (mounted) setState(() => loadingProfile = false);
    }
  }

  Future<void> _loadProfile() async {
    try {
      final response = await _apiService.getProfile();
      Map<String, dynamic> userData;
      
      // Handle format response yang mungkin beda
      if (response.containsKey('user')) {
        userData = response['user'];
      } else {
        userData = response;
      }

      if (!mounted) return;
      setState(() {
        userName = userData["name"] ?? "Nama User";
        userBio = userData["bio"] ?? "Belum ada bio";
        userPhoto = userData["photo_url"] ?? userData["profile_photo_path"] ?? ""; 
      });
    } catch (e) {
      print("Gagal load profil: $e");
    }
  }

  Future<void> _loadTasks() async {
    try {
      final tasksData = await _apiService.getTasks();
      if (mounted) {
        setState(() => _tasks = tasksData);
      }
    } catch (e) {
      print("Gagal load tugas: $e");
    }
  }

  // --- 2. FUNGSI LOGOUT ---
  void _logout(BuildContext context) async {
    final GoogleAuthService googleAuthService = GoogleAuthService();
    
    // Logout Google (Fire & Forget)
    try { await googleAuthService.signOut(); } catch (_) {}

    // Logout Backend
    try {
      await _apiService.logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal logout: $e')));
      }
    }
  }

  // --- 3. WIDGET HEADER PROFIL (Lokal) ---
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          // Foto Profil
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey[200],
            backgroundImage: userPhoto.isNotEmpty ? NetworkImage(userPhoto) : null,
            child: userPhoto.isEmpty ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
          ),
          const SizedBox(width: 16),

          // Nama, Bio, Tombol Edit
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loadingProfile ? "Memuat..." : userName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  loadingProfile ? "..." : userBio,
                  style: TextStyle(color: Colors.grey[600]),
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis,
                ),
                
                TextButton(
                  onPressed: () async {
                    final bool? updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(
                          currentName: userName,
                          currentBio: userBio,
                          currentPhotoUrl: userPhoto,
                        ),
                      ),
                    );

                    if (updated == true) {
                      _loadAllData(); // Refresh jika ada perubahan
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.centerLeft,
                  ),
                  child: const Text("Edit Profil"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. UI UTAMA ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Background abu-abu muda
      
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: () => _logout(context), 
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: "Keluar",
          ),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAllData, // Tarik ke bawah untuk refresh
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                _buildProfileHeader(),
                
                const SizedBox(height: 24),
                const Text("Ringkasan Statistik", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                
                // KARTU RINGKASAN
                TaskSummaryCards(tasks: _tasks),
                
                const SizedBox(height: 16),
                
                // CHART MINGGUAN (Curve)
                WeeklyLineChart(tasks: _tasks),
                
                const SizedBox(height: 24),
                
                // LIST TUGAS BELUM SELESAI (Expandable/Minimize)
                ExpandableUnfinishedTasks(
                  tasks: _tasks,
                  onRefresh: _loadAllData, // Callback agar profil refresh jika task diedit
                ),

                const SizedBox(height: 24),
                
                // PIE CHART
                UnfinishedPieChart(tasks: _tasks),
                
                const SizedBox(height: 40), // Spasi bawah
              ],
            ),
          ),
        ),
      ),
    );
  }
}