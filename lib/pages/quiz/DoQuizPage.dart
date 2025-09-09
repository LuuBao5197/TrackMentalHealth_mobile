import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackmentalhealth/core/constants/api_constants.dart';

import '../../models/quizSubmitRespone.dart';
import '../../models/quiz_submitssion.dart';

class DoQuizPage extends StatefulWidget {
  final int quizId;
  const DoQuizPage({super.key, required this.quizId});

  @override
  State<DoQuizPage> createState() => _DoQuizPageState();
}

class _DoQuizPageState extends State<DoQuizPage> {
  bool isLoading = true;
  bool isError = false;
  List<Map<String, dynamic>> questions = [];

  int currentQuestionIndex = 0;
  final Map<int, dynamic> answers = {};
  List<int> markedForReview = [];
  bool isFinished = false;

  PageController pageController = PageController();

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    try {
      final res =
      await http.get(Uri.parse("${ApiConstants.baseUrl}/quizzes/${widget.quizId}"));
      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        final data = decoded["quizQuestions"] as List;
        setState(() {
          questions = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load questions");
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  void toggleMarkReview(int qId) {
    setState(() {
      if (markedForReview.contains(qId)) {
        markedForReview.remove(qId);
      } else {
        markedForReview.add(qId);
      }
    });
  }

  void scrollToQuestion(int index) {
    pageController.jumpToPage(index);
    setState(() => currentQuestionIndex = index);
  }

  Future<void> submitTest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final userId = prefs.getInt("userId") ?? 0;

      // build list answers
      final answersList = questions.map((q) {
        final value = answers[q["id"]];
        final type = q["type"];

        if (type == "TEXT_INPUT" || type == "TEXT") {
          return AnswerDto(
            questionId: q["id"],
            userInput: value ?? "",
          );
        } else if (type == "MULTI_CHOICE") {
          return AnswerDto(
            questionId: q["id"],
            selectedOptionIds: value != null ? List<int>.from(value) : [],
          );
        } else if (type == "SINGLE_CHOICE" ||
            type == "SCORE_BASED" ||
            type == "TRUE_FALSE" ||
            type == "MCQ") {
          return AnswerDto(
            questionId: q["id"],
            selectedOptionIds: value != null ? [value] : [],
          );
        } else if (type == "MATCHING") {
          final matchingItems =
          List<Map<String, dynamic>>.from(q["matchingItems"]);
          return AnswerDto(
            questionId: q["id"],
            matchingPairs: List.generate(matchingItems.length, (i) {
              return MatchingPair(
                leftText: matchingItems[i]["leftItem"],
                rightText: value[i],
              );
            }),
          );
        } else if (type == "ORDERING") {
          final orderingItems =
          List<Map<String, dynamic>>.from(q["orderingItems"]);
          return AnswerDto(
            questionId: q["id"],
            orderingItems: List.generate(value.length, (i) {
              final item =
              orderingItems.firstWhere((it) => it["content"] == value[i]);
              return OrderingItem(
                itemId: item["id"],
                text: item["content"],
                userOrder: i + 1,
              );
            }),
          );
        }

        return AnswerDto(questionId: q["id"]); // fallback
      }).toList();

      final submission = QuizSubmission(
        quizId: widget.quizId,
        userId: userId,
        answers: answersList,
      );

      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/quiz/submit"),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode(submission.toJson()), // 🎯 gọn gàng
      );
      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = QuizSubmitResponse.fromJson(data);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bạn đạt ${result.totalScore} điểm - ${result.resultLabel}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Nộp bài thất bại: $e")),
      );
    }
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
            Text("Danh sách câu hỏi",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 12),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final q = questions[index];
                  Color bgColor =
                  isDark ? Colors.grey.shade800 : Colors.white;
                  if (answers.containsKey(q["id"])) bgColor = Colors.green;
                  if (markedForReview.contains(q["id"])) bgColor = Colors.purple;

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
                      child: Text("${index + 1}",
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context),
              child: const Text("Đóng"),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildQuestionCard(Map<String, dynamic> q, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final type = q["type"];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header + mark review
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Câu ${currentQuestionIndex + 1}/${questions.length}",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87),
              ),
              GestureDetector(
                onTap: () => toggleMarkReview(q["id"]),
                child: Row(
                  children: [
                    Text("Mark for review",
                        style: TextStyle(
                            color:
                            isDark ? Colors.white : Colors.black87)),
                    const SizedBox(width: 6),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: markedForReview.contains(q["id"])
                            ? Colors.purple
                            : (isDark
                            ? Colors.grey.shade900
                            : Colors.white),
                        border: Border.all(color: Colors.purple),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Html(data: q["content"] ?? ""),
          const SizedBox(height: 12),

          // render theo type
          if (type == "MCQ") _buildMCQ(q, isDark),
          if (type == "TRUE_FALSE") _buildTrueFalse(q, isDark),
          if (type == "TEXT") _buildText(q, isDark),
          if (type == "ORDERING") _buildOrdering(q),
          if (type == "MATCHING") _buildMatching(q),
        ],
      ),
    );
  }

  Widget _buildMCQ(Map<String, dynamic> q, bool isDark) {
    final options = List<String>.from(q["options"] ?? []);
    return Column(
      children: options.map((opt) {
        return RadioListTile(
          title: Text(opt,
              style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87)),
          value: opt,
          groupValue: answers[q["id"]],
          onChanged: (val) => setState(() => answers[q["id"]] = val),
        );
      }).toList(),
    );
  }

  Widget _buildTrueFalse(Map<String, dynamic> q, bool isDark) {
    return Row(
      children: ["True", "False"].map((val) {
        return Expanded(
          child: RadioListTile(
            title: Text(val,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87)),
            value: val,
            groupValue: answers[q["id"]],
            onChanged: (v) => setState(() => answers[q["id"]] = v),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildText(Map<String, dynamic> q, bool isDark) {
    final controller =
    TextEditingController(text: answers[q["id"]] ?? "");
    return TextField(
      controller: controller,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      onChanged: (val) => answers[q["id"]] = val,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
    );
  }

  Widget _buildOrdering(Map<String, dynamic> q) {
    final items =
        q["orderingItems"]?.map((e) => e["content"] as String).toList() ?? [];
    answers[q["id"]] ??= List<String>.from(items);

    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = answers[q["id"]].removeAt(oldIndex);
          answers[q["id"]].insert(newIndex, item);
        });
      },
      children: [
        for (int i = 0; i < answers[q["id"]].length; i++)
          ListTile(
            key: ValueKey(answers[q["id"]][i]),
            title: Text(answers[q["id"]][i]),
            leading: const Icon(Icons.drag_handle),
          ),
      ],
    );
  }

  Widget _buildMatching(Map<String, dynamic> q) {
    final items = List<Map<String, dynamic>>.from(q["matchingItems"]);
    final leftItems = items.map((e) => e["leftItem"] as String).toList();
    answers[q["id"]] ??=
    items.map((e) => e["rightItem"] as String).toList()..shuffle();
    final rightItems = List<String>.from(answers[q["id"]]);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        // Left column
        Expanded(
          child: Column(
            children: leftItems
                .map(
                  (e) => Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  e,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            )
                .toList(),
          ),
        ),
        const SizedBox(width: 8),
        // Right column (Reorderable)
        Expanded(
          child: ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = rightItems.removeAt(oldIndex);
                rightItems.insert(newIndex, item);
                answers[q["id"]] = rightItems;
              });
            },
            children: [
              for (int i = 0; i < rightItems.length; i++)
                ListTile(
                  key: ValueKey(rightItems[i]),
                  title: Text(
                    rightItems[i],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  leading: Icon(
                    Icons.drag_handle,
                    color: colorScheme.primary,
                  ),
                  tileColor: colorScheme.primaryContainer.withOpacity(0.5),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (isError || questions.isEmpty) {
      return Scaffold(
        body: Center(
            child: Text("❌ Lỗi khi tải dữ liệu",
                style: TextStyle(color: isDark ? Colors.white : Colors.black87))),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
      appBar: AppBar(
        title: const Text("Do Quiz"),
        actions: [
          if (!isLandscape) // chỉ hiện nút danh sách khi ở dọc
            IconButton(
              icon: const Icon(Icons.list_alt),
              onPressed: () => showDialog(
                  context: context,
                  builder: (_) => questionListDialog(brightness)),
            ),
        ],
      ),
      body: isFinished
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("🎉 Bạn đã hoàn thành quiz!",
                style:
                TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  currentQuestionIndex = 0;
                  answers.clear();
                  markedForReview.clear();
                  isFinished = false;
                });
              },
              child: const Text("Làm lại"),
            )
          ],
        ),
      )
          : isLandscape
      // 👉 Landscape: chia đôi màn hình
          ? Row(
        children: [
          // cột câu hỏi
          Expanded(
            flex: 3,
            child: PageView.builder(
              controller: pageController,
              onPageChanged: (index) =>
                  setState(() => currentQuestionIndex = index),
              itemCount: questions.length,
              itemBuilder: (context, index) =>
                  buildQuestionCard(questions[index], brightness),
            ),
          ),
          // cột trạng thái
          Expanded(
            flex: 1,
            child: Container(
              color: isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade100,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Text("Trạng thái câu hỏi",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark
                              ? Colors.white
                              : Colors.black87)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6),
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        final q = questions[index];
                        Color bgColor = isDark
                            ? Colors.white
                            : Colors.white;
                        if (answers.containsKey(q["id"])) {
                          bgColor = Colors.green;
                        }
                        if (markedForReview.contains(q["id"])) {
                          bgColor = Colors.purple;
                        }

                        return GestureDetector(
                          onTap: () => scrollToQuestion(index),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Text(
                              "${index + 1}",
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black87),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      )
      // 👉 Portrait: chỉ hiển thị câu hỏi
          : PageView.builder(
        controller: pageController,
        onPageChanged: (index) =>
            setState(() => currentQuestionIndex = index),
        itemCount: questions.length,
        itemBuilder: (context, index) =>
            buildQuestionCard(questions[index], brightness),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          onPressed: submitTest,
          style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.orange),
          child: const Text("NỘP BÀI",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

}
