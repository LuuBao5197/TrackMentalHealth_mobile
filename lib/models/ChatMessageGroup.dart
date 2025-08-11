import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ChatMessageGroup {
  final int id;
  final int groupId;
  final int senderId;
  final String senderName;
  final String content;
  final DateTime sendAt;

  ChatMessageGroup({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.sendAt,
  });

  factory ChatMessageGroup.fromJson(Map<String, dynamic> json) {
    return ChatMessageGroup(
      id: json['id'] ?? 0,
      groupId: json['groupId'] ?? 0,
      senderId: json['senderId'] ?? 0,
      senderName: json['senderName'] ?? '',
      content: json['content'] ?? '',
      sendAt: json['sendAt'] != null
          ? DateTime.parse(json['sendAt'])
          : DateTime.now(),
    );
  }



  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'sendAt': sendAt.toIso8601String(),
    };
  }


  types.TextMessage toTextMessage(String currentUserId) {
    return types.TextMessage(
      id: id.toString(),
      author: types.User(
        id: senderId.toString(),
        firstName: senderName,
      ),
      createdAt: sendAt.millisecondsSinceEpoch,
      text: content,
    );
  }
}
