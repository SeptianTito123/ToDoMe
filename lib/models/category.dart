// lib/models/category.dart

import 'dart:convert';

// Parser untuk list (GET /api/categories)
List<Category> categoryFromJson(String str) => List<Category>.from(json.decode(str).map((x) => Category.fromJson(x)));

class Category {
    int id;
    String name;
    int userId;
    int tasksCount;
    DateTime createdAt;
    DateTime updatedAt;

    Category({
        required this.id,
        required this.name,
        required this.userId,
        required this.tasksCount,
        required this.createdAt,
        required this.updatedAt,
    });

    factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json["id"],
        name: json["name"],
        userId: json["user_id"],
        tasksCount: json["tasks_count"] ?? 0,
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "user_id": userId,
        "tasks_count": tasksCount,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
    };
}