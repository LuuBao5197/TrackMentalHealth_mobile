import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = "http://192.168.3.7:9999/api";

// 🛡️ Hàm lấy header có token thực từ SharedPreferences
Future<Map<String, String>> getHeaders() async {
  const fakeToken = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhbmhAZXhhbXBsZS5jb20iLCJ1c2VySWQiOjksInJvbGUiOiJVU0VSIiwicm9sZXMiOlsiUk9MRV9VU0VSIl0sImlhdCI6MTc1NDAyNTU3OCwiZXhwIjoxNzU0MDYxNTc4fQ.vDSuPi0aCSVuJeI49am0K0k515bNP-YDfOsbbUFQsXs"; // <-- Dán token thật của bạn ở đây

  return {
    "Content-Type": "application/json",
    "Authorization": "Bearer $fakeToken",
  };
}


// 🧠 Lấy danh sách mức cảm xúc
Future<List<dynamic>> getMoodLevels() async {
  final headers = await getHeaders();
  final response = await http.get(Uri.parse("$baseUrl/mood-levels"), headers: headers);

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Không thể lấy danh sách mức cảm xúc");
  }
}

// 🧠 Lấy mood hôm nay của người dùng
Future<Map<String, dynamic>?> getTodayMood() async {
  final headers = await getHeaders();
  final response = await http.get(Uri.parse("$baseUrl/moods/my/today"), headers: headers);

  if (response.statusCode == 200) {
    if (response.body.isEmpty || response.body == "null") return null;
    return jsonDecode(response.body);
  } else {
    throw Exception("Không thể lấy mood hôm nay");
  }
}

// 🧠 Tạo mood mới
Future<Map<String, dynamic>> createMood(Map<String, dynamic> mood) async {
  final headers = await getHeaders();
  final response = await http.post(
    Uri.parse("$baseUrl/moods"),
    headers: headers,
    body: jsonEncode(mood),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    // 🔍 IN RA LỖI CHI TIẾT
    print("🛑 createMood LỖI: ${response.statusCode}");
    print("🛑 BODY: ${response.body}");
    throw Exception("Không thể tạo mood mới");
  }
}


// 🧠 Cập nhật mood
Future<Map<String, dynamic>> updateMood(int id, Map<String, dynamic> mood) async {
  final headers = await getHeaders();
  final response = await http.put(
    Uri.parse("$baseUrl/moods/$id"),
    headers: headers,
    body: jsonEncode(mood),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Không thể cập nhật mood");
  }
}
