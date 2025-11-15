// lib/models/task.dart

import 'dart:convert';
import 'category.dart';
import 'subtask.dart';

List<Task> taskFromJson(String str) => List<Task>.from(json.decode(str).map((x) => Task.fromJson(x)));

String taskToJson(List<Task> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Task {
    int id;
    int userId;
    String judul;
    String? deskripsi;
    bool statusSelesai;
    bool isStarred;
    DateTime? deadline;
    DateTime createdAt;
    DateTime updatedAt;
    List<Category>? categories; 
    List<Subtask>? subtasks;

    Task({
        required this.id,
        required this.userId,
        required this.judul,
        this.deskripsi,
        required this.statusSelesai,
        required this.isStarred,
        this.deadline,
        required this.createdAt,
        required this.updatedAt,
        this.categories, 
        this.subtasks,
    });

    factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json["id"],
        userId: json["user_id"],
        judul: json["judul"],
        deskripsi: json["deskripsi"],
        statusSelesai: json["status_selesai"] == 1 || json["status_selesai"] == true,
        isStarred: json["is_starred"] == 1 || json["is_starred"] == true,
        deadline: json["deadline"] == null ? null : DateTime.parse(json["deadline"]),
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        categories: json["categories"] == null
            ? []
            : List<Category>.from(json["categories"]!.map((x) => Category.fromJson(x))),
        subtasks: json["subtasks"] == null
          ? []
          : List<Subtask>.from(json["subtasks"]!.map((x) => Subtask.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "judul": judul,
        "deskripsi": deskripsi,
        "status_selesai": statusSelesai,
        "is_starred": isStarred,
        "deadline": deadline?.toIso8601String(),
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "categories": categories == null
            ? []
            : List<dynamic>.from(categories!.map((x) => x.toJson())),
        "subtasks": subtasks == null
            ? []
            : List<dynamic>.from(subtasks!.map((x) => x.toJson())),
    };
}

// <-- 2. KELAS KATEGORI YANG LAMA DIHAPUS DARI SINI