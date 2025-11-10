import 'dart:convert'; // Untuk jsonEncode/Decode
import 'package:http/http.dart' as http; // Package http yang tadi di-add
import '../models/task.dart'; // Model Task yang sudah kita buat

class ApiService {
  // ⚠️ PENTING: Lihat penjelasan di bawah tentang IP Address ini
  // Ini adalah alamat server backend Laravel Anda
  // (Pastikan server Laravel Anda berjalan: php artisan serve)
  static const String _baseUrl = "http://10.0.2.2:8000/api";

  // Header default, kita memberi tahu server bahwa kita mengirim/menerima JSON
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // -----------------------------------------------------------
  // 1. READ: Mengambil SEMUA data tugas (GET /tasks)
  // -----------------------------------------------------------
  Future<List<Task>> getTasks() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tasks'),
        headers: _headers,
      );

      // Jika server merespon "OK" (sukses)
      if (response.statusCode == 200) {
        // Kita gunakan helper 'taskFromJson' dari model kita
        // untuk mengubah List JSON menjadi List<Task>
        return taskFromJson(response.body);
      } else {
        // Jika gagal, lemparkan error
        throw Exception('Gagal mengambil data tasks. Status: ${response.statusCode}');
      }
    } catch (e) {
      // Menangkap error (misal: tidak ada koneksi internet)
      throw Exception('Error saat getTasks: $e');
    }
  }

  // -----------------------------------------------------------
  // 2. CREATE: Membuat tugas BARU (POST /tasks)
  // -----------------------------------------------------------
  Future<Task> createTask(String judul, String? deskripsi) async {
    try {
      final body = jsonEncode({
        'judul': judul,
        'deskripsi': deskripsi,
      });

      final response = await http.post(
        Uri.parse('$_baseUrl/tasks'),
        headers: _headers,
        body: body,
      );

      // Jika server merespon "Created" (sukses)
      if (response.statusCode == 201) {
        // Ubah balasan JSON dari server menjadi satu objek Task
        return Task.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Gagal membuat task. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saat createTask: $e');
    }
  }

  // -----------------------------------------------------------
  // 3. UPDATE: Mengubah data tugas (PUT /tasks/{id})
  // -----------------------------------------------------------
  Future<Task> updateTaskStatus(int id, bool statusSelesai) async {
     try {
      final body = jsonEncode({
        'status_selesai': statusSelesai,
      });

      final response = await http.put(
        Uri.parse('$_baseUrl/tasks/$id'),
        headers: _headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return Task.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Gagal mengupdate status task. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saat updateTaskStatus: $e');
    }
  }

  // -----------------------------------------------------------
  // 4. DELETE: Menghapus tugas (DELETE /tasks/{id})
  // -----------------------------------------------------------
  Future<void> deleteTask(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/tasks/$id'),
        headers: _headers,
      );

      // Jika status BUKAN 204 (No Content), berarti gagal
      if (response.statusCode != 204) {
        throw Exception('Gagal menghapus task. Status: ${response.statusCode}');
      }
      // Jika sukses (204), tidak perlu mengembalikan apa-apa
    } catch (e) {
      throw Exception('Error saat deleteTask: $e');
    }
  }
}