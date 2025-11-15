// lib/models/subtask.dart
import 'dart:convert';

class Subtask {
    int id;
    int taskId;
    String title;
    bool isCompleted;

    Subtask({
        required this.id,
        required this.taskId,
        required this.title,
        required this.isCompleted,
    });

    factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
        id: json["id"],
        taskId: json["task_id"],
        title: json["title"],
        isCompleted: json["is_completed"] == 1 || json["is_completed"] == true,
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "task_id": taskId,
        "title": title,
        "is_completed": isCompleted,
    };
}