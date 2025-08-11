import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// TODO: Thay thế hàm này bằng logic thực tế để lấy token từ secure storage hoặc shared_preferences
Future<String?> getToken() async {
  // Ví dụ giả định
  return 'your_jwt_token_here';
}

class MentalAlertBox extends StatefulWidget {
  const MentalAlertBox({super.key});

  @override
  State<MentalAlertBox> createState() => _MentalAlertBoxState();
}

class _MentalAlertBoxState extends State<MentalAlertBox> {
  Map<String, dynamic>? result;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchMentalAnalysis();
  }

  Future<void> fetchMentalAnalysis() async {
    final token = await getToken();
    if (token == null) return;

    final url = Uri.parse('http://172.16.3.156:9999/api/mental/analyze');

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        setState(() {
          result = json.decode(response.body);
          loading = false;
        });
      } else {
        setState(() {
          result = {
            'description': 'Không thể lấy thông tin phân tích tâm lý.',
            'suggestion': null,
          };
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        result = {
          'description': 'Lỗi khi gọi API.',
          'suggestion': null,
        };
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Text("Đang phân tích dữ liệu tâm lý...");

    final suggestion = result?['suggestion'];

    return Card(
      color: Colors.yellow[100],
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📢 Cảnh báo sức khỏe tinh thần",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(result?['description'] ?? 'Không có mô tả.'),

            if (suggestion != null && suggestion['type'] == 'test') ...[
              const SizedBox(height: 12),
              Text(
                "🧪 Gợi ý bài test phù hợp: ${suggestion['testTitle']}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(suggestion['testDescription'] ?? ''),
              const SizedBox(height: 4),
              Text("Hướng dẫn: ${suggestion['instructions']}"),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.quiz),
                label: const Text("👉 Làm bài test ngay"),
                onPressed: () {
                  final testId = suggestion['testId'];
                  Navigator.pushNamed(
                    context,
                    '/doTest/$testId',
                  );
                },
              ),
            ],

            if (suggestion != null && suggestion['type'] == 'emergency') ...[
              const SizedBox(height: 12),
              const Text(
                "🚨 Cảnh báo khẩn cấp",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              Text(suggestion['message'] ?? ''),
            ]
          ],
        ),
      ),
    );
  }
}
