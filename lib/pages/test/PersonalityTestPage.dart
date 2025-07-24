import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../models/AnswerRequest.dart';

// void main() {
//   runApp(const MaterialApp(
//     home: PersonalityTestPage(),
//     debugShowCheckedModeBanner: false,
//   ));
// }

class PersonalityTestPage extends StatefulWidget {
  final int testId;
  const PersonalityTestPage({super.key, required this.testId});
  @override
  State<PersonalityTestPage> createState() => _PersonalityTestPageState();
}

class _PersonalityTestPageState extends State<PersonalityTestPage> {
  int currentQuestionIndex = 0;
  Map<int, int> selectedAnswers = {};
  int totalScore = 0;
  bool isFinished = false;

  bool isLoading = true;
  bool isError = false;
  Map<String, dynamic>? testData;

  @override
  void initState() {
    super.initState();
    fetchTestData();
  }

  Future<void> fetchTestData() async {
    try {
      final response =
      await http.get(Uri.parse('${ApiConstants.baseUrl}/tests}/${widget.testId}'));

      if (response.statusCode == 200) {
        setState(() {
          testData = json.decode(utf8.decode(response.bodyBytes));
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load test data");
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  Future<void> nextQuestion() async {
    final questionId = testData!['questions'][currentQuestionIndex]['id'];
    if (selectedAnswers[questionId] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn một đáp án!")),
      );
      return;
    }

    if (currentQuestionIndex < testData!['questions'].length - 1) {
      setState(() => currentQuestionIndex++);
    } else {
      // Kiểm tra xem có câu nào chưa trả lời
      final unanswered = testData!['questions'].where((q) => !selectedAnswers.containsKey(q['id'])).toList();
      if (unanswered.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠️ Bạn chưa trả lời ${unanswered.length} câu hỏi."),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      totalScore = selectedAnswers.values.fold(0, (a, b) => a + b);
      setState(() => isFinished = true);
      await saveResult();
    }

  }

  void previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() => currentQuestionIndex--);
    }
  }

  String getResultText() {
    final results = testData!['results'];
    for (var result in results) {
      if (totalScore >= result['minScore'] &&
          totalScore <= result['maxScore']) {
        return result['resultText'];
      }
    }
    return "Không xác định được kết quả.";
  }
  Future<void> saveResult() async {
    final userId = 1; // Hoặc lấy từ token/session
    final testId = testData!['id'];

    final answers = selectedAnswers.entries.map((entry) {
      return AnswerRequest(
        questionId: entry.key,
        selectedOptionId: entry.value,
      );
    }).toList();

    final totalScore = selectedAnswers.entries.map((entry) {
      final question = testData!['questions']
          .firstWhere((q) => q['id'] == entry.key);
      final option = question['options']
          .firstWhere((opt) => opt['id'] == entry.value);
      return option['scoreValue'] as int;
    }).fold(0, (a, b) => a + b);

    final submission = TestSubmissionRequest(
      userId: userId,
      testId: testId,
      totalScore: totalScore,
      answers: answers,
    );

    final url = Uri.parse('${ApiConstants.baseUrl}/test-result');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(submission.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Kết quả đã được lưu thành công');
      } else {
        debugPrint('❌ Lỗi khi lưu: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❗ Lỗi kết nối: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (isError || testData == null) {
      return const Scaffold(
        body: Center(child: Text("Đã xảy ra lỗi khi tải dữ liệu.")),
      );
    }

    final question = testData!['questions'][currentQuestionIndex];
    final totalQuestions = testData!['questions'].length;

    return Scaffold(
      appBar: AppBar(
        title: Text(testData!['title'] ?? "Bài kiểm tra"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width > 600 ? 700 : double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: isFinished
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("🎉 Kết quả của bạn:",
                        style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Text(getResultText(), style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        currentQuestionIndex = 0;
                        selectedAnswers.clear();
                        totalScore = 0;
                        isFinished = false;
                      }),
                      child: const Text("Làm lại"),
                    ),
                  ],
                )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      "🧠 Tổng số câu: ${testData!['questions'].length}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),

// ✅ Thanh điều hướng 5 số gần current
                    Builder(
                      builder: (context) {
                        final totalQuestions = testData!['questions'].length;
                        final start = (currentQuestionIndex - 2).clamp(0, totalQuestions - 5).toInt();
                        final end = (start + 5).clamp(0, totalQuestions).toInt();

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(end - start, (i) {
                            final index = start + i;
                            final qId = testData!['questions'][index]['id'];
                            final isSelected = selectedAnswers.containsKey(qId);
                            final isCurrent = index == currentQuestionIndex;

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isCurrent
                                        ? Colors.teal
                                        : (isSelected
                                        ? Colors.blue.shade100
                                        : Colors.red.shade100),
                                    foregroundColor: Colors.black,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      currentQuestionIndex = index;
                                    });
                                  },
                                  child: Text('${index + 1}'),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: 16),


                    const SizedBox(height: 16),

                    LinearProgressIndicator(
                      value: (currentQuestionIndex + 1) / totalQuestions,
                      backgroundColor: Colors.grey[300],
                      color: Colors.blue,
                      minHeight: 8,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Câu ${currentQuestionIndex + 1}/$totalQuestions",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(question['questionText'],
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 20),
                    ...List.generate(question['options'].length, (index) {
                      final option = question['options'][index];
                      return RadioListTile<int>(
                        title: Text(option['optionText']),
                        value: option['scoreValue'],
                        groupValue: selectedAnswers[question['id']],
                        onChanged: (value) {
                          setState(() {
                            selectedAnswers[question['id']] = value!;
                          });
                        },
                      );
                    }),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (currentQuestionIndex > 0)
                          ElevatedButton(
                            onPressed: previousQuestion,
                            child: const Text("← Quay lại"),
                          ),
                        ElevatedButton(
                          onPressed: nextQuestion,
                          child: Text(currentQuestionIndex < totalQuestions - 1
                              ? "Tiếp theo →"
                              : "Xem kết quả"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Các widgets như Text, RadioListTile, ProgressBar...
            ],
          ),
        ),
      ),


    );
  }
}
