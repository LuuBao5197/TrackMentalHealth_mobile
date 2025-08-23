import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_constants.dart';

const String baseUrl = "http://${ApiConstants.ipLocal}:9999/api";

Future<Map<String, String>> getHeaders() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token");
  if (token == null) throw Exception("Token chưa được lưu");

  return {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };
}

Future<List<dynamic>> getMoodLevels() async {
  final headers = await getHeaders();
  final res = await http.get(Uri.parse("$baseUrl/mood-levels"), headers: headers);

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception("Không thể lấy danh sách mức cảm xúc");
  }
}

Future<Map<String, dynamic>?> getTodayMood() async {
  final headers = await getHeaders();
  final res = await http.get(Uri.parse("$baseUrl/moods/my/today"), headers: headers);

  if (res.statusCode == 200) {
    if (res.body.isEmpty || res.body == "null") return null;
    return jsonDecode(res.body);
  } else {
    throw Exception("Không thể lấy mood hôm nay");
  }
}

Future<Map<String, dynamic>> createMood(Map<String, dynamic> mood) async {
  final headers = await getHeaders();
  final res = await http.post(
    Uri.parse("$baseUrl/moods"),
    headers: headers,
    body: jsonEncode(mood),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception("Không thể tạo mood mới");
  }
}

Future<Map<String, dynamic>> updateMood(int id, Map<String, dynamic> mood) async {
  final headers = await getHeaders();
  final res = await http.put(
    Uri.parse("$baseUrl/moods/$id"),
    headers: headers,
    body: jsonEncode(mood),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception("Không thể cập nhật mood");
  }
}

Future<Map<String, dynamic>?> getMoodByUserAndDate(int userId, String date) async {
  final headers = await getHeaders();
  final res = await http.get(
    Uri.parse("$baseUrl/moods/user/$userId/date/$date"),
    headers: headers,
  );

  if (res.statusCode == 200) {
    if (res.body.isEmpty || res.body == "null") return null;
    return jsonDecode(res.body);
  } else {
    throw Exception("Không thể lấy mood theo user & date");
  }
}

Future<List<dynamic>> getMyMoods() async {
  final headers = await getHeaders();
  final res = await http.get(Uri.parse("$baseUrl/moods/my"), headers: headers);

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception("Không thể lấy lịch sử moods");
  }
}

Future<Map<String, dynamic>> getMyMoodsPaged({int page = 0, int size = 5}) async {
  final headers = await getHeaders();
  final res = await http.get(
    Uri.parse("$baseUrl/moods/my/page?page=$page&size=$size"),
    headers: headers,
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception("Không thể lấy moods phân trang");
  }
}

Future<Map<String, dynamic>> getMoodStatistics() async {
  final headers = await getHeaders();
  final res = await http.get(Uri.parse("$baseUrl/moods/my/statistics"), headers: headers);

  if (res.statusCode == 200) {
    return jsonDecode(res.body) as Map<String, dynamic>;
  } else {
    throw Exception("Không thể lấy thống kê moods");
  }
}

