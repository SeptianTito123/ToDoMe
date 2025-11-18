import 'package:flutter/material.dart';

// Import dari branch profil
import 'profile_header.dart';
import 'task_summary_cards.dart';
import 'weekly_line_chart.dart';
import 'upcoming_tasks.dart';
import 'unfinished_pie_chart.dart';

// Import dari branch main
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  // Fungsi logout dari branch main
  void _logout(BuildContext context) async {
    final ApiService apiService = ApiService();
    try {
      await apiService.logout();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          )
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              ProfileHeader(),
              SizedBox(height: 20),

              Text(
                "Ringkasan Tugas",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              TaskSummaryCards(),
              SizedBox(height: 16),

              WeeklyLineChart(),
              SizedBox(height: 16),

              UpcomingTasks(),
              SizedBox(height: 16),

              UnfinishedPieChart(),
            ],
          ),
        ),
      ),
    );
  }
}
