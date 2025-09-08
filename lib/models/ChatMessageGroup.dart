import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'User.dart';

class ChatMessageGroup {
  final int id;
  final String content;
  final DateTime? sendAt;
  final User sender;

  ChatMessageGroup({
    required this.id,
    required this.content,
    required this.sendAt,
    required this.sender,
  });

  factory ChatMessageGroup.fromJson(Map<String, dynamic> json) {
    return ChatMessageGroup(
      id: json['id'] as int,
      content: json['content'] ?? '',
      sendAt: json['sendAt'] != null ? DateTime.parse(json['sendAt']) : null,
      sender: User.fromJson(json['sender']),
    );
  }

  /// Convert sang flutter_chat_ui TextMessage
  types.TextMessage toTextMessage(String currentUserId) {
    final msg = types.TextMessage(
      id: id.toString(),
      author: types.User(
        id: sender.id.toString(),
        firstName: sender.fullName,
        imageUrl: sender.avatar,
      ),
      text: content,
      createdAt: sendAt?.millisecondsSinceEpoch,
    );

    // ✅ Debug log
    print("💬 Msg[${msg.id}] "
        "authorId=${msg.author.id}, "
        "currentUserId=$currentUserId, "
        "isMine=${msg.author.id == currentUserId}");

    return msg;
  }
}
