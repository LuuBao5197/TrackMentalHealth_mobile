import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";

      final res = await http.get(
        Uri.parse("http://172.16.2.28:9999/api/mental/analyze"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        setState(() {
          result = json.decode(res.body);
          loading = false;
        });
      } else {
        setState(() {
          result = {
            "description": "Không thể lấy thông tin phân tích tâm lý.",
            "suggestion": null,
          };
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        result = {
          "description": "Không thể lấy thông tin phân tích tâm lý.",
          "suggestion": null,
        };
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text("Đang phân tích dữ liệu tâm lý..."),
      );
    }

    return Card(
      color: Colors.amber.shade100,
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📢 Cảnh báo sức khỏe tinh thần",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(result?["description"] ?? "Không có mô tả."),

            // Nếu là gợi ý test
            if (result?["suggestion"]?["type"] == "test") ...[
              const SizedBox(height: 12),
              Text(
                "🧪 Gợi ý bài test phù hợp: ${result?["suggestion"]["testTitle"] ?? ""}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(result?["suggestion"]["testDescription"] ?? ""),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    "/user/doTest/${result?["suggestion"]["testId"]}",
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                ),
                child: const Text("👉 Làm bài test ngay"),
              ),
            ],

            // Nếu là cảnh báo khẩn cấp
            if (result?["suggestion"]?["type"] == "emergency") ...[
              const SizedBox(height: 12),
              const Text(
                "🚨 Cảnh báo khẩn cấp",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              Text(result?["suggestion"]["message"] ?? ""),
            ],
          ],
        ),
      ),
    );
  }
}
