import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DiaryApi {
  static const String baseUrl = 'http://172.16.2.28:9999/api/diaries'; // đổi IP LAN

  // Lấy headers kèm token
  static Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Hàm xử lý chung cho request
  static Future<dynamic> _handleRequest(Future<http.Response> Function() requestFn) async {
    final res = await requestFn();
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isNotEmpty ? jsonDecode(res.body) : null;
    } else {
      throw Exception('Lỗi API (${res.statusCode}): ${res.body}');
    }
  }

  /// Lấy danh sách nhật ký của user (cho Diary History)
  static Future<List<dynamic>> getDiaries() async {
    final headers = await _getAuthHeaders();
    return await _handleRequest(
          () => http.get(Uri.parse('$baseUrl/my'), headers: headers),
    );
  }

  static Future<http.Response> createDiary(String content) async {
    final headers = await _getAuthHeaders();
    return await http.post(
      Uri.parse(baseUrl), // ✅ bỏ /create
      headers: headers,
      body: jsonEncode({
        "content": content,
      }),
    );
  }




  /// Cập nhật nhật ký
  static Future<dynamic> updateDiary(int id, String content, String date) async {
    final headers = await _getAuthHeaders();
    return await _handleRequest(
          () => http.put(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
        body: jsonEncode({
          'content': content,
          'date': date,
        }),
      ),
    );
  }


  /// Xóa nhật ký
  static Future<dynamic> deleteDiary(int id) async {
    final headers = await _getAuthHeaders();
    return await _handleRequest(
          () => http.delete(Uri.parse('$baseUrl/$id'), headers: headers),
    );
  }
}
