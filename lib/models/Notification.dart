import 'package:flutter/foundation.dart';

class Notification {
  final int id;
  final int userId; // thay vì object Users, chỉ lưu userId
  final String type;
  bool isRead;
  final String title;
  final String description;
  final String message;
  final DateTime datetime;

  Notification({
    required this.id,
    required this.userId,
    required this.type,
    this.isRead = false,
    required this.title,
    required this.description,
    required this.message,
    required this.datetime,
  });

  // Factory từ JSON (ví dụ từ API backend)
  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      userId: json['user'] != null
          ? json['user']['id'] ?? json['userId']
          : json['userId'] ?? 0,
      type: json['type'] ?? '',
      isRead: json['isRead'] ?? false,
      title: json['title'] ?? '',
      description: json['des'] ?? json['description'] ?? '',
      message: json['message'] ?? '',
      datetime: json['datetime'] != null
          ? DateTime.parse(json['datetime'])
          : DateTime.now(),
    );
  }

  // Chuyển thành JSON (ví dụ gửi lên API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'isRead': isRead,
      'title': title,
      'des': description,
      'message': message,
      'datetime': datetime.toIso8601String(),
    };
  }
}
