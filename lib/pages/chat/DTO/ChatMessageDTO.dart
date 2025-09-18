import 'dart:convert';

class ChatMessageDTO {
  final String message;
  final int senderId;
  final String senderName;

  ChatMessageDTO({
    required this.message,
    required this.senderId,
    required this.senderName,
  });

  factory ChatMessageDTO.fromRawJson(String str) =>
      ChatMessageDTO.fromJson(jsonDecode(str));

  factory ChatMessageDTO.fromJson(Map<String, dynamic> json) {
    return ChatMessageDTO(
      message: json['message'] ?? '',
      senderId: json['senderId'],
      senderName: json['senderName'] ?? '',
    );
  }

  factory ChatMessageDTO.fromMap(Map<String, dynamic> map) {
    return ChatMessageDTO(
      senderId: map['senderId'],
      senderName: map['senderName'],
      message: map['message'],
    );
  }
}
