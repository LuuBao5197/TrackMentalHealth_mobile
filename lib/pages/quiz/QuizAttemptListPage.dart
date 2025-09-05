import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:trackmentalhealth/core/constants/api_constants.dart';
import 'dart:convert';

import 'QuizAttemptDetailPage.dart';

class QuizAttemptListPage extends StatefulWidget {
  final int userId;
  const QuizAttemptListPage({super.key, required this.userId});

  @override
  State<QuizAttemptListPage> createState() => _QuizAttemptListPageState();
}

class _QuizAttemptListPageState extends State<QuizAttemptListPage> {
  List attempts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchAttempts();
  }

  Future<void> fetchAttempts() async {
    final res = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/quiz/history/${widget.userId}"),
    );
    if (res.statusCode == 200) {
      setState(() {
        attempts = jsonDecode(res.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(title: const Text("My Quiz Attempts")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : attempts.isEmpty
          ? const Center(child: Text("No attempts found."))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("#")),
                  DataColumn(label: Text("Quiz Title")),
                  DataColumn(label: Text("Start")),
                  DataColumn(label: Text("End")),
                  DataColumn(label: Text("Score")),
                  DataColumn(label: Text("Action")),
                ],
                rows: attempts.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final attempt = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text("${idx + 1}")),
                      DataCell(Text("${attempt["quizTitle"]}")),
                      DataCell(
                        Text(
                          "${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(attempt["startTime"]).toLocal())}",
                        ),
                      ),
                      DataCell(
                        Text(
                          "${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(attempt["endTime"]).toLocal())}",
                        ),
                      ),
                      DataCell(Text("${attempt["totalScore"]}")),
                      DataCell(
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuizAttemptDetailPage(
                                  attemptId: attempt["attemptId"],
                                ),
                              ),
                            );
                          },
                          child: const Text("View Detail"),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
    );
  }
}
