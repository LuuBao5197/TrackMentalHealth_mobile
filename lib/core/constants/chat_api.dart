import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const String ipLocal = '192.168.1.5';
const String baseUrl = 'http://${ipLocal}:9999/api';

// ==== Chat ====
const String chatUrl = '$baseUrl/chat/';
const String appointmentUrl = '$baseUrl/appointment/';
const String psyUrl = '$baseUrl/psychologist/';
const String aiUrl = '$baseUrl/chatai/';
const String notificationUrl = '$baseUrl/notification/';
const String chatGroupUrl = '$baseUrl/chatgroup/';
const String uploadUrl = '$baseUrl/upload';

// ==================== Upload File ====================
Future<String> uploadFile(File file) async {
  var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
  request.files.add(await http.MultipartFile.fromPath('file', file.path));
  var response = await request.send();

  if (response.statusCode == 200) {
    final res = await http.Response.fromStream(response);
    return jsonDecode(res.body)['url'];
  } else {
    throw Exception('Upload failed');
  }
}

// ==================== Chat Messages ====================
Future<List<dynamic>> getMessagesBySessionId(int id) async {
  final res = await http.get(Uri.parse('$chatUrl$id'));
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to fetch messages');
  }
}

Future<bool> hasUnreadMessages(int id) async {
  final res = await http.get(Uri.parse('$chatUrl/has-unread/$id'));
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to check unread');
  }
}

Future<dynamic> initiateChatSession(int senderId, int receiverId) async {
  final res = await http.post(Uri.parse('$chatUrl/session/initiate/$senderId/$receiverId'));
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to initiate session');
  }
}

Future<List<dynamic>> getChatSessionsByUserId(int id) async {
  final res = await http.get(Uri.parse('$chatUrl/session/$id'));
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to get chat sessions');
  }
}

// ==================== Appointment ====================
Future<List<dynamic>> getAppointmentByUserId(int id) async {
  final res = await http.get(Uri.parse('$appointmentUrl/list/$id'));
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to fetch appointments');
  }
}

Future<dynamic> getAppointmentById(int id) async {
  final res = await http.get(Uri.parse('$appointmentUrl$id'));
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to fetch appointment');
  }
}

Future<List<dynamic>> getAppointmentByPsyId(int psyId) async {
  final res = await http.get(Uri.parse('$appointmentUrl/psychologist/$psyId'));
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to fetch appointments by psy');
  }
}

Future<dynamic> saveAppointment(Map<String, dynamic> data) async {
  final res = await http.post(
    Uri.parse('${appointmentUrl}save'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to save appointment');
  }
}

Future<dynamic> updateAppointment(int id, Map<String, dynamic> data) async {
  final res = await http.put(
    Uri.parse('$appointmentUrl$id'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to update appointment');
  }
}

Future<dynamic> deleteAppointment(int id) async {
  final res = await http.delete(Uri.parse('$appointmentUrl$id'));
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to delete appointment');
  }
}

// ==================== Psychologists ====================
Future<List<dynamic>> getPsychologists() async {
  final res = await http.get(Uri.parse(psyUrl));
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to fetch psychologists');
  }
}

// ==================== AI ====================
Future<dynamic> chatAI(Map<String, dynamic> data) async {
  final res = await http.post(
    Uri.parse('${aiUrl}ask'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to chat AI');
  }
}

Future<List<dynamic>> getAIHistory(int userId) async {
  final res = await http.get(Uri.parse('${aiUrl}history/$userId'));
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to fetch AI history');
  }
}

// ==================== Notifications ====================
Future<List<dynamic>> getNotificationsByUserId(int userId) async {
  final res = await http.get(Uri.parse('$notificationUrl/user/$userId'));
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to fetch notifications');
  }
}

Future<dynamic> saveNotification(Map<String, dynamic> data) async {
  final res = await http.post(
    Uri.parse('${notificationUrl}save'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to save notification');
  }
}

Future<dynamic> changeStatusNotification(int id) async {
  final res = await http.put(Uri.parse('${notificationUrl}changestatus/$id'));
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to change notification status');
  }
}

Future<dynamic> deleteNotificationById(int id) async {
  final res = await http.delete(Uri.parse('${notificationUrl}delete/$id'));
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to delete notification');
  }
}

// ==================== Chat Group ====================
Future<List<dynamic>> getAllChatGroup() async {
  final res = await http.get(Uri.parse('${chatGroupUrl}findAll'));
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to get chat groups');
  }
}

Future<List<dynamic>> getChatGroupByCreatorId(int id) async {
  final res = await http.get(Uri.parse('${chatGroupUrl}createdBy/$id'));
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to get chat group by creator');
  }
}

Future<dynamic> getChatGroupById(int id) async {
  final res = await http.get(Uri.parse('$chatGroupUrl$id'));
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to get chat group by id');
  }
}

Future<List<dynamic>> getMessagesByGroupId(int id) async {
  final res = await http.get(Uri.parse('${chatGroupUrl}messages/$id'));
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to get group messages');
  }
}

Future<List<dynamic>> findUsersByGroupId(int groupId, int currentUserId) async {
  final res = await http.get(Uri.parse('${chatGroupUrl}group/users/$groupId/$currentUserId'));
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to get users in group');
  }
}

Future<dynamic> deleteGroupById(int id) async {
  final res = await http.delete(Uri.parse('${chatGroupUrl}delete/$id'));
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to delete group');
  }
}

Future<dynamic> createNewGroup(Map<String, dynamic> groupData, File? file) async {
  var request = http.MultipartRequest('POST', Uri.parse('${chatGroupUrl}create'));
  request.fields['chatGroup'] = jsonEncode(groupData);
  if (file != null) {
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
  }
  var response = await request.send();

  if (response.statusCode == 200) {
    final res = await http.Response.fromStream(response);
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to create group');
  }
}

Future<dynamic> updateGroupById(int id, Map<String, dynamic> data) async {
  final res = await http.put(
    Uri.parse('${chatGroupUrl}edit/$id'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to update group');
  }
}

Future<dynamic> changeStatusIsRead(int sessionId, int receiverId) async {
  final res = await http.put(Uri.parse('${chatUrl}changeStatus/$sessionId/$receiverId'));
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to change message status');
  }
}
