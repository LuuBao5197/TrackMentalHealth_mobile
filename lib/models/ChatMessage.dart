import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ChatMessage {
  final int id;
  final int senderId;
  final int receiverId;
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['sender']['id'],
      receiverId: json['receiver']['id'],
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  /// Convert sang TextMessage của flutter_chat_ui
  types.TextMessage toTextMessage(String currentUserId) {
    return types.TextMessage(
      id: id.toString(),
      author: types.User(id: senderId.toString()),
      text: message,
      createdAt: timestamp.millisecondsSinceEpoch,
    );
  }
}
