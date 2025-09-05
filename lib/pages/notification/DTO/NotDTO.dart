Map<String, dynamic> NotDTO(int userId, String msg) {
  return {
    "user": {"id": userId},
    "type": "system",
    "title": "New notification",
    "des": "There is a new event",
    "message": msg,
    "datetime": DateTime.now().toIso8601String(),
    "isRead": false,
  };
}
