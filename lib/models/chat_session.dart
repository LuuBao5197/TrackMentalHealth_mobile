class ChatSession {
  final int id;
  final Map<String, dynamic>? sender;   // chứa id, name...
  final Map<String, dynamic>? receiver; // chứa id, name...
  final String? startTime;
  final String? endTime;
  final String? status;

  ChatSession({
    required this.id,
    this.sender,
    this.receiver,
    this.startTime,
    this.endTime,
    this.status,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      sender: json['sender'],
      receiver: json['receiver'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      status: json['status'],
    );
  }
}
