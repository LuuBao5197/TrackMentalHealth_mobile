import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:trackmentalhealth/models/ChatMessageGroup.dart';
import 'package:http_parser/http_parser.dart';

import '../../models/Appointment.dart';
import '../../models/ChatMessage.dart';
import '../../models/Psychologist.dart';
import 'api_constants.dart' as api_constants;

final ip = api_constants.ApiConstants.ipLocal;
final String baseUrl = 'http://${ip}:9999/api';

// ==== Chat ====
final String chatUrl = '$baseUrl/chat';
final String appointmentUrl = '$baseUrl/appointment';
final String psyUrl = '$baseUrl/psychologist';
final String aiUrl = '$baseUrl/chatai';
final String notificationUrl = '$baseUrl/notification';
final String chatGroupUrl = '$baseUrl/chatgroup';
final String uploadUrl = '$baseUrl/upload';
final String reviewUrl = '$baseUrl/review';


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
  final res = await http.get(Uri.parse('$chatUrl/$id'));
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

Future<ChatMessage?> getLastestMsg(int sessionId) async {
  final res = await http.get(Uri.parse('$chatUrl/lastest-message/$sessionId'));
  if (res.statusCode == 200) {
    return ChatMessage.fromJson(jsonDecode(res.body));
  } else if (res.statusCode == 404) {
    return null; // Chưa có tin nhắn
  } else {
    throw Exception('Failed to load lastest message');
  }
}

Future<ChatMessageGroup?> getLastestMsgGroup(int groupId) async {
  final res = await http.get(
    Uri.parse('$chatGroupUrl/lastest-message/$groupId'),
  );

  if (res.statusCode == 200) {
    final jsonData = jsonDecode(res.body);
    return ChatMessageGroup.fromJson(jsonData);
  } else if (res.statusCode == 404) {
    return null; // Chưa có tin nhắn
  } else {
    throw Exception('Failed to load latest message');
  }
}

Future<dynamic> initiateChatSession(int senderId, int receiverId) async {
  final res = await http.post(
    Uri.parse('$chatUrl/session/initiate/$senderId/$receiverId'),
  );
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to initiate session');
  }
}

Future<List<dynamic>> getChatSessionsByUserId(int userId) async {
  final res = await http.get(Uri.parse('$chatUrl/session/$userId'));
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    print('Error ${res.statusCode}: ${res.body}');
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
  final res = await http.get(Uri.parse('${appointmentUrl}/$id'));
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

Future<Appointment> saveAppointment(Map<String, dynamic> data) async {
  try {
    final res = await http.post(
      Uri.parse('$appointmentUrl/save'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    print("Response status: ${res.statusCode}");
    print("Response body: ${res.body}");

    if (res.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(res.body);
      return Appointment.fromJson(json);
    } else if (res.statusCode == 409) {
      // Conflict: đã có lịch hẹn đang chờ với chuyên gia này
      throw Exception("CONFLICT");
    } else {
      throw Exception('Failed to save appointment: ${res.statusCode}');
    }
  } catch (e) {
    throw Exception('Error saving appointment: $e');
  }
}

Future<dynamic> updateAppointment(int id, Map<String, dynamic> data) async {
  final res = await http.put(
    Uri.parse('$appointmentUrl/$id'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );

  if (res.statusCode == 200) {
    if (res.body.isNotEmpty) {
      return jsonDecode(res.body);
    } else {
      return {"message": "Update successful"}; // hoặc trả về data đã gửi
    }
  } else if (res.statusCode == 409) {
    throw Exception("CONFLICT: Appointment already exists");
  } else {
    throw Exception('Failed to update appointment: ${res.statusCode}');
  }
}


Future<dynamic> deleteAppointment(int id) async {
  final res = await http.delete(Uri.parse('$appointmentUrl/$id'));
  if (res.statusCode == 200) {
    if (res.body.isNotEmpty) {
      return jsonDecode(res.body);
    }
    return null;
  } else {
    throw Exception('Failed to delete appointment: ${res.statusCode}');
  }
}


// ==================== Psychologists ====================
Future<List<Psychologist>> getPsychologists() async {
  final res = await http.get(Uri.parse('$psyUrl/'));
  if (res.statusCode == 200) {
    final List<dynamic> data = jsonDecode(res.body);
    return data.map((e) => Psychologist.fromJson(e)).toList();
  } else {
    throw Exception('Failed to fetch psychologists');
  }
}

// ==================== AI ====================
Future<String> chatAI(Map<String, dynamic> data) async {
  final res = await http.post(
    Uri.parse('$aiUrl/ask'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );

  if (res.statusCode == 200) {
    return res.body; // Backend trả string thuần
  } else {
    throw Exception('Failed to chat AI: ${res.statusCode} ${res.body}');
  }
}

Future<List<dynamic>> getAIHistory(int userId) async {
  final url = '${aiUrl}/history/$userId';
  debugPrint("Gọi API getAIHistory: $url");

  final res = await http.get(Uri.parse(url));

  debugPrint("Status code: ${res.statusCode}");
  debugPrint("Response body: ${res.body}");

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to fetch AI history: ${res.statusCode}');
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
    Uri.parse('${notificationUrl}/save'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to save notification');
  }
}

Future<void> changeStatusNotification(int id) async {
  final res = await http.put(Uri.parse('${notificationUrl}/changestatus/$id'));

  if (res.statusCode != 200) {
    throw Exception('Failed to change notification status: ${res.statusCode}');
  }
}

Future<dynamic> deleteNotificationById(int id) async {
  final res = await http.delete(Uri.parse('${notificationUrl}/delete/$id'));
  if (res.statusCode != 200) {
    throw Exception('Failed to delete notification');
  }
}

// ==================== Chat Group ====================
Future<List<dynamic>> getAllChatGroup() async {
  final res = await http.get(Uri.parse('${chatGroupUrl}/findAll'));
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to get chat groups');
  }
}

Future<List<dynamic>> getChatGroupByCreatorId(int id) async {
  final res = await http.get(Uri.parse('${chatGroupUrl}/createdBy/$id'));
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to get chat group by creator');
  }
}

Future<dynamic> getChatGroupById(int id) async {
  final res = await http.get(Uri.parse('$chatGroupUrl/$id'));

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to get chat group by id');
  }
}

Future<List<dynamic>> getMessagesByGroupId(int id) async {
  final res = await http.get(Uri.parse('${chatGroupUrl}/messages/$id'));
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to get group messages');
  }
}

Future<List<dynamic>> findUsersByGroupId(int groupId, int currentUserId) async {
  final res = await http.get(
    Uri.parse('${chatGroupUrl}/group/users/$groupId/$currentUserId'),
  );
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to get users in group');
  }
}

Future<dynamic> deleteGroupById(int id) async {
  final res = await http.delete(Uri.parse('$chatGroupUrl/delete/$id'));

  if (res.statusCode == 200 || res.statusCode == 204) {
    if (res.body.isNotEmpty) {
      return jsonDecode(res.body);
    } else {
      return true; // chỉ báo thành công
    }
  } else {
    throw Exception('Failed to delete group: ${res.statusCode}');
  }
}


Future<dynamic> createNewGroup(
  Map<String, dynamic> groupData,
  File? file,
) async
{
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('${chatGroupUrl}/create'),
  );

  // Gửi chatGroup dạng JSON với content-type application/json
  request.files.add(
    http.MultipartFile.fromString(
      'chatGroup',
      jsonEncode(groupData),
      contentType: MediaType('application', 'json'),
    ),
  );

  if (file != null) {
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
  }

  var response = await request.send();
  final res = await http.Response.fromStream(response);

  debugPrint("➡️ Status: ${response.statusCode}");
  debugPrint("➡️ Body: ${res.body}");

  if (response.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to create group: ${res.body}');
  }
}

Future<dynamic> updateGroupById(int id, Map<String, dynamic> data) async {
  final res = await http.put(
    Uri.parse('$chatGroupUrl/edit/$id'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to update group: ${res.body}');
  }
}

Future<dynamic> changeStatusIsRead(int sessionId, int receiverId) async {
  final res = await http.put(
    Uri.parse('${chatUrl}/changeStatus/$sessionId/$receiverId'),
  );
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed to change message status');
  }
}

//
Future<double> getAverageRatingByPsychologist(int psyId) async {
  final res = await http.get(
    Uri.parse('${reviewUrl}/average/$psyId'),
  );
  if (res.statusCode == 200) {
    // API trả về trực tiếp double
    return double.tryParse(res.body) ?? 0.0;
  } else {
    throw Exception('Failed to get average rating');
  }
}

//
Future<Map<String, dynamic>> createReviewByAppointmentId(int id, Map<String, dynamic> data) async {
  final url = Uri.parse('$reviewUrl/appointment/$id');
  try {
    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Failed to create review. StatusCode: ${res.statusCode}');
    }
  } catch (e) {
    print('Lỗi createReviewByAppointmentId: $e');
    rethrow;
  }
}

