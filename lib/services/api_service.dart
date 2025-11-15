import 'dart:io'; // Untuk deteksi platform
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../models/subtask.dart'; // Impor Subtask

class ApiService {
  // --- KONFIGURASI DASAR ---

  static final String _baseUrl = Platform.isAndroid ? "http://10.0.2.2:8000/api" : "http://127.0.0.1:8000/api";

  final _storage = const FlutterSecureStorage();

  // --- HELPER INTERNAL ---

  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- 1. FUNGSI AUTENTIKASI ---

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'auth_token', value: data['access_token']);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Error saat login: $e");
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, String passwordConfirmation) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Error saat register: $e");
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/logout'),
        headers: await _getHeaders(), 
      );
    } catch (e) {
      print("Error saat API logout: $e");
    } finally {
      await _storage.delete(key: 'auth_token');
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token != null;
  }

  // --- 2. FUNGSI TASK ---

  Future<List<Task>> getTasks() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tasks'),
        headers: await _getHeaders(), 
      );

      if (response.statusCode == 200) {
        return taskFromJson(response.body);
      } else if (response.statusCode == 401) {
        await logout(); 
        throw Exception('Sesi habis. Silakan login kembali.');
      } else {
        throw Exception('Gagal mengambil tasks. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saat getTasks: $e');
    }
  }

  // --- FUNGSI BARU UNTUK BUAT TUGAS (dengan Subtugas) ---
  Future<Task> createTask({
    required String judul,
    String? deskripsi,
    DateTime? deadline,
    List<int>? categoryIds,
    List<String>? subtasks, // List of string
  }) async {
    try {
      final body = jsonEncode({
        'judul': judul,
        'deskripsi': deskripsi,
        'deadline': deadline?.toIso8601String(),
        'category_ids': categoryIds,
        'subtasks': subtasks, // Kirim list of string
      });

      final response = await http.post(
        Uri.parse('$_baseUrl/tasks'),
        headers: await _getHeaders(),
        body: body,
      );

      if (response.statusCode == 201) {
        return Task.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Gagal membuat task. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saat createTask: $e');
    }
  }
  
  // --- FUNGSI BARU UNTUK UPDATE TUGAS (BINTANG / SELESAI) ---
  Future<Task> updateTask(int taskId, Map<String, dynamic> data) async {
    try {
      // data bisa berupa: {'is_starred': true} atau {'status_selesai': false}
      final response = await http.put(
        Uri.parse('$_baseUrl/tasks/$taskId'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return Task.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Gagal mengupdate tugas. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saat updateTask: $e');
    }
  }
  
  // --- 3. FUNGSI CATEGORY ---

  Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/categories'),
        headers: await _getHeaders(), 
      );

      if (response.statusCode == 200) {
        return categoryFromJson(response.body); 
      } else if (response.statusCode == 401) {
        await logout(); 
        throw Exception('Sesi habis. Silakan login kembali.');
      } else {
        throw Exception('Gagal mengambil kategori. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saat getCategories: $e');
    }
  }
  
  // --- FUNGSI BARU UNTUK BUAT KATEGORI ---
  Future<Category> createCategory(String name) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/categories'),
        headers: await _getHeaders(),
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode == 201) {
        return Category.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Gagal membuat kategori. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saat createCategory: $e');
    }
  }

  // --- 4. FUNGSI SUBTASK ---

  // --- FUNGSI BARU UNTUK MENCENTANG SUBTUGAS ---
  Future<Subtask> updateSubtask(int subtaskId, bool isCompleted) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/subtasks/$subtaskId'),
        headers: await _getHeaders(),
        body: jsonEncode({'is_completed': isCompleted}),
      );

      if (response.statusCode == 200) {
        return Subtask.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Gagal mengupdate subtask. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saat updateSubtask: $e');
    }
  }

  // --- FUNGSI BARU UNTUK MENGHAPUS SUBTUGAS ---
  Future<void> deleteSubtask(int subtaskId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/subtasks/$subtaskId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 204) {
        throw Exception('Gagal menghapus subtask. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saat deleteSubtask: $e');
    }
  }

  Future<void> deleteTask(int taskId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/tasks/$taskId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 204) {
        throw Exception('Gagal menghapus tugas. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saat deleteTask: $e');
    }
  }

  // --- FUNGSI BARU UNTUK BUAT SUBTUGAS (di task yg ada) ---
  Future<Subtask> createSubtask(int taskId, String title) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tasks/$taskId/subtasks'),
        headers: await _getHeaders(),
        body: jsonEncode({'title': title}),
      );

      if (response.statusCode == 201) {
        return Subtask.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Gagal membuat subtask. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saat createSubtask: $e');
    }
  }
}