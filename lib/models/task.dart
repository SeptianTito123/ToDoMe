import 'dart:convert'; // Diperlukan untuk jsonDecode dan jsonEncode

// Fungsi helper untuk mengubah List<dynamic> dari API menjadi List<Task>
List<Task> taskFromJson(String str) => List<Task>.from(json.decode(str).map((x) => Task.fromJson(x)));

// Fungsi helper untuk mengubah satu objek Task menjadi String JSON (untuk dikirim ke API)
String taskToJson(Task data) => json.encode(data.toJson());

class Task {
    // Properti ini HARUS SAMA dengan nama kolom di database/API Anda
    int id;
    String judul;
    String? deskripsi; // Boleh null
    bool statusSelesai;
    DateTime? deadline; // Boleh null
    DateTime createdAt;
    DateTime updatedAt;

    Task({
        required this.id,
        required this.judul,
        this.deskripsi,
        required this.statusSelesai,
        this.deadline,
        required this.createdAt,
        required this.updatedAt,
    });

    // Factory constructor untuk "membangun" objek Task dari data JSON
    // Ini adalah "penerjemah" dari Laravel -> Flutter
    factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json["id"],
        judul: json["judul"],
        deskripsi: json["deskripsi"],

        // API kita mengirimkan 'status_selesai' sebagai 0 atau 1 (boolean di MySQL)
        // Kode ini mengubah angka 0/1 itu jadi true/false di Dart
        statusSelesai: json["status_selesai"] == 1 || json["status_selesai"] == true, 

        // API kita mengirim 'deadline', 'created_at', 'updated_at' sebagai String
        // Kita ubah menjadi objek DateTime di Dart
        deadline: json["deadline"] == null ? null : DateTime.parse(json["deadline"]),
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
    );

    // Method untuk "mengemas" objek Task menjadi JSON
    // Ini adalah "penerjemah" dari Flutter -> Laravel (saat kita membuat/update)
    Map<String, dynamic> toJson() => {
        // "id": id, // Kita tidak perlu mengirim ID saat membuat data baru
        "judul": judul,
        "deskripsi": deskripsi,
        "status_selesai": statusSelesai,
        "deadline": deadline?.toIso8601String(), // '?' handle jika null
        // Kita tidak perlu mengirim created_at/updated_at, Laravel mengurusnya
    };
}