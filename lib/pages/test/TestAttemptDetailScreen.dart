import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:trackmentalhealth/core/constants/api_constants.dart';

class TestAttemptDetailScreen extends StatefulWidget {
  final int attemptId;

  const TestAttemptDetailScreen({super.key, required this.attemptId});

  @override
  State<TestAttemptDetailScreen> createState() =>
      _TestAttemptDetailScreenState();
}

class _TestAttemptDetailScreenState extends State<TestAttemptDetailScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _testDetail;

  Future<void> fetchTestDetail() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final res = await http.get(
        Uri.parse(
          "${ApiConstants.baseUrl}/test/getTestHistory/test_attempt/${widget.attemptId}",
        ),
      );

      if (res.statusCode == 200) {
        setState(() {
          _testDetail = jsonDecode(res.body);
        });
      } else {
        setState(() => _error = "Failed to load test details.");
      }
    } catch (e) {
      setState(() => _error = "Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTestDetail();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Test Attempt Detail")),
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    final detail = _testDetail!;
    final List<dynamic> questions = detail["detailDTOList"] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text("📝 ${detail["testTitle"]}")),
      body: OrientationBuilder(
        builder: (context, orientation) {
          bool isLandscape = orientation == Orientation.landscape;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Start time: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(detail["startedAt"]).toLocal())}",
                ),
                Text(
                  "Completed At: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(detail["completedAt"]).toLocal())}",
                ),
                Text("Total Score: ${detail["totalScore"]}"),
                Text(
                  "Result: ${detail["resultLabel"]}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                ...questions.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final q = entry.value;
                  final options = q["options"] as List<dynamic>;
                  final selected = q["selectedOptionText"];

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child:
                      isLandscape
                          ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cột câu hỏi
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                "Q${idx + 1}: ${q["questionInstruction"]}\n${q["questionText"]}",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Cột đáp án
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: options.map((opt) {
                                final isSelected = opt["optionText"] == selected;
                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.green.shade100 : null,
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text("${opt["optionText"]} (${opt["scoreValue"]})"),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      )

                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Question ${idx + 1}: ${q["questionInstruction"]}: ${q["questionText"]}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Column(
                            children: options.map((opt) {
                              final isSelected = opt["optionText"] == selected;
                              final isDark = Theme.of(context).brightness == Brightness.dark;

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark ? Colors.teal.shade700.withOpacity(0.5) : Colors.green.shade100)
                                      : null,
                                  border: Border.all(
                                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "${opt["optionText"]} (${opt["scoreValue"]})",
                                  style: TextStyle(
                                    color: isDark
                                        ? (isSelected ? Colors.white : Colors.grey.shade200)
                                        : null,
                                  ),
                                ),
                              );



                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      )
      ,
    );
  }
}
