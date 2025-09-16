import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:trackmentalhealth/core/constants/api_constants.dart';

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
        Uri.parse("http://${ApiConstants.ipLocal}:9999/api/mental/analyze"),
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
            "description": "Unable to fetch mental health analysis.",
            "suggestion": null,
          };
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        result = {
          "description": "Unable to fetch mental health analysis.",
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
        child: Text("Analyzing mental health data..."),
      );
    }

    final isStable = result?["level"] == 1;

    return Card(
      color: isStable ? Colors.green.shade100 : Colors.amber.shade100,
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isStable
                  ? "💡 Your mental state is stable"
                  : "📢 Mental Health Alert",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(result?["description"] ?? "No description available."),

            // Motivation suggestion
            if (result?["suggestion"]?["type"] == "motivation") ...[
              const SizedBox(height: 12),
              const Text(
                "🌱",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 16,
                ),
              ),
              Text(result?["suggestion"]["message"] ?? ""),
            ],

            // Suggested test
            if (result?["suggestion"]?["type"] == "test") ...[
              const SizedBox(height: 12),
              Text(
                "🧪 Suggested Test: ${result?["suggestion"]["testTitle"] ?? ""}",
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
                child: const Text("👉 Take the test now"),
              ),
            ],

            // Emergency alert
            if (result?["suggestion"]?["type"] == "emergency") ...[
              const SizedBox(height: 12),
              const Text(
                "🚨 Emergency Alert",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              Text(result?["suggestion"]["message"] ?? ""),
            ],
            if (result?["level"] == 4) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, "/user/doTest");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red.shade900,
                ),
                icon: const Icon(Icons.medical_services),
                label: const Text("Talk to a doctor"),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
