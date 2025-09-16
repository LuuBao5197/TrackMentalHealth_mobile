import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';
import '../../models/AnswerRequest.dart';

class PersonalityTestPage extends StatefulWidget {
  final int testId;
  const PersonalityTestPage({super.key, required this.testId});

  @override
  State<PersonalityTestPage> createState() => _PersonalityTestPageState();
}

class _PersonalityTestPageState extends State<PersonalityTestPage> {
  int currentQuestionIndex = 0;
  Map<int, int> selectedAnswers = {};
  List<int> markedForReview = [];
  int totalScore = 0;
  bool isFinished = false;

  bool isLoading = true;
  bool isError = false;
  Map<String, dynamic>? testData;

  PageController pageController = PageController();

  @override
  void initState() {
    super.initState();
    fetchTestData();
  }

  Future<void> fetchTestData() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/test/${widget.testId}'),
      );

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

  void toggleMarkReview(int questionId) {
    setState(() {
      if (markedForReview.contains(questionId)) {
        markedForReview.remove(questionId);
      } else {
        markedForReview.add(questionId);
      }
    });
  }

  void scrollToQuestion(int index) {
    pageController.jumpToPage(index);
    setState(() => currentQuestionIndex = index);
  }

  String getResultText() {
    final results = testData!['results'];
    for (var result in results) {
      if (totalScore >= result['minScore'] &&
          totalScore <= result['maxScore']) {
        return result['resultText'];
      }
    }
    return "Result could not be determined.";
  }

  Future<void> saveResult() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("userId");
    final token = prefs.getString("token");

    if (userId == null) return;

    final testId = testData!['id'];

    final answers = selectedAnswers.entries.map((entry) {
      return AnswerRequest(
        questionId: entry.key,
        selectedOptionId: entry.value,
      );
    }).toList();

    final submission = TestSubmissionRequest(
      userId: userId,
      testId: testId,
      totalScore: totalScore,
      answers: answers,
    );

    final url = Uri.parse('${ApiConstants.baseUrl}/test/submitUserTestResult');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(submission.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Result saved successfully');
      } else {
        debugPrint('❌ Error saving result: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❗ Connection error: $e');
    }
  }

  void submitTest() {
    final unanswered = testData!['questions']
        .where((q) => !selectedAnswers.containsKey(q['id']))
        .toList();
    if (unanswered.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ You have not answered ${unanswered.length} questions."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    totalScore = selectedAnswers.entries
        .map((entry) {
      final question = testData!['questions'].firstWhere(
            (q) => q['id'] == entry.key,
      );
      final option = question['options'].firstWhere(
            (opt) => opt['id'] == entry.value,
      );
      return option['scoreValue'] as int;
    })
        .fold(0, (a, b) => a + b);

    setState(() => isFinished = true);
    saveResult();
  }

  Widget questionListDialog(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return Dialog(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(12),
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Question List",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: testData!['questions'].length,
                itemBuilder: (context, index) {
                  final q = testData!['questions'][index];
                  Color bgColor = isDark ? Colors.grey.shade800 : Colors.white;
                  if (selectedAnswers.containsKey(q['id'])) bgColor = Colors.green;
                  if (markedForReview.contains(q['id'])) bgColor = Colors.purple;

                  return GestureDetector(
                    onTap: () {
                      scrollToQuestion(index);
                      Navigator.pop(context);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Text(
                        "${q['questionOrder']}",
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildQuestionCard(Map<String, dynamic> q, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Question ${currentQuestionIndex + 1}/${testData!['questions'].length}",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87),
              ),
              GestureDetector(
                onTap: () => toggleMarkReview(q['id']),
                child: Row(
                  children: [
                    Text("Mark for review",
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(width: 6),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: markedForReview.contains(q['id'])
                            ? Colors.purple
                            : isDark
                            ? Colors.grey.shade900
                            : Colors.white,
                        border: Border.all(color: Colors.purple),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(q['questionText'],
              style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 12),
          ...List.generate(q['options'].length, (idx) {
            final opt = q['options'][idx];
            return RadioListTile<int>(
              value: opt['id'],
              groupValue: selectedAnswers[q['id']],
              onChanged: (val) {
                setState(() {
                  selectedAnswers[q['id']] = val!;
                });
              },
              title: Text(opt['optionText'],
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              activeColor: Colors.orange,
              tileColor: isDark ? Colors.grey.shade800 : Colors.white,
            );
          }),
        ],
      ),
    );
  }

  Widget buildResultView(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            "🎉 Your Result:",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 16),
          Text(
            getResultText(),
            style: TextStyle(fontSize: 18, color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                currentQuestionIndex = 0;
                selectedAnswers.clear();
                markedForReview.clear();
                totalScore = 0;
                isFinished = false;
              });
            },
            child: const Text("Retake Test"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (isError || testData == null)
      return Scaffold(
        body: Center(
            child: Text(
              "Error occurred while loading data.",
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            )),
      );

    final totalQuestions = testData!['questions'].length;
    final question = testData!['questions'][currentQuestionIndex];

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.blue,
        foregroundColor: Colors.white,
        title: Text(testData!['title'] ?? "Personality Test"),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () => showDialog(context: context, builder: (_) => questionListDialog(brightness)),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;

          Widget mainContent = Expanded(
            flex: 2,
            child: isFinished
                ? buildResultView(brightness)
                : PageView.builder(
              controller: pageController,
              onPageChanged: (index) {
                setState(() => currentQuestionIndex = index);
              },
              itemCount: totalQuestions,
              itemBuilder: (context, index) => buildQuestionCard(testData!['questions'][index], brightness),
            ),
          );

          Widget sideBar = !isMobile
              ? Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(12),
              color: isDark ? Colors.grey.shade800 : Colors.grey[100],
              child: Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                      ),
                      itemCount: totalQuestions,
                      itemBuilder: (context, index) {
                        final q = testData!['questions'][index];
                        Color bgColor = isDark ? Colors.grey.shade700 : Colors.white;
                        if (selectedAnswers.containsKey(q['id'])) bgColor = Colors.green;
                        if (markedForReview.contains(q['id'])) bgColor = Colors.purple;

                        return GestureDetector(
                          onTap: () => scrollToQuestion(index),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Text("${q['questionOrder']}",
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: submitTest,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text(
                      "SUBMIT",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          )
              : const SizedBox();

          return Row(children: [mainContent, sideBar]);
        },
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;
          if (isMobile) {
            return Container(
              padding: const EdgeInsets.all(12),
              color: isDark ? Colors.grey.shade900 : Colors.white,
              child: ElevatedButton(
                onPressed: submitTest,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.orange,
                ),
                child: const Text(
                  "SUBMIT",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
