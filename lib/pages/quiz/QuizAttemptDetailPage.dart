import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

import 'package:trackmentalhealth/core/constants/api_constants.dart';

class QuizAttemptDetailPage extends StatefulWidget {
  final int attemptId;
  const QuizAttemptDetailPage({super.key, required this.attemptId});

  @override
  State<QuizAttemptDetailPage> createState() => _QuizAttemptDetailPageState();
}

class _QuizAttemptDetailPageState extends State<QuizAttemptDetailPage> {
  Map<String, dynamic>? quizDetail;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    final res = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/quiz/detail/${widget.attemptId}"),
    );
    if (res.statusCode == 200) {
      setState(() {
        quizDetail = jsonDecode(res.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (quizDetail == null) {
      return const Scaffold(
        body: Center(child: Text("Không có dữ liệu")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Html(data: quizDetail!["quizTitle"])),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            "Start:  ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(quizDetail!["startTime"]).toLocal())}",
          ),
          Text(
            "End: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(quizDetail!["endTime"]).toLocal())}",
          ),
          Text("Total Score: ${quizDetail!["totalScore"]}"),
          Text("Result: ${quizDetail!["resultLabel"]}"),
          const SizedBox(height: 16),
          ExpansionPanelList.radio(
            children: (quizDetail!["answers"] as List).asMap().entries.map((entry) {
              final idx = entry.key;
              final q = entry.value;

              return ExpansionPanelRadio(
                value: idx,
                headerBuilder: (_, __) => ListTile(
                  title: Html(data: "${idx + 1}. ${q["questionText"]}"),
                  subtitle: Text("Type: ${q["questionType"]}"),
                ),
                body: _buildAnswerWidget(q),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerWidget(Map<String, dynamic> q) {
    switch (q["questionType"]) {
      case "MATCHING":
        return Table(
          border: TableBorder.all(),
          children: (q["matchingAnswers"] as List).map<TableRow>((pair) {
            return TableRow(children: [
              Padding(
                  padding: const EdgeInsets.all(8), child: Text(pair["leftText"])),
              Padding(
                  padding: const EdgeInsets.all(8), child: Text(pair["rightText"])),
            ]);
          }).toList(),
        );

      case "ORDERING":
        final items = (q["orderingAnswers"] as List)
          ..sort((a, b) => a["userOrder"].compareTo(b["userOrder"]));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map<Widget>((it) => Text("• ${it["text"]}")).toList(),
        );

      case "TEXT_INPUT":
        return Text("User Input: ${q["userInput"]}");

      case "SINGLE_CHOICE":
      case "MULTI_CHOICE":
      case "SCORE_BASED":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: (q["selectedOptions"] as List).map<Widget>((opt) {
            return Text(
              opt["content"],
              style: TextStyle(
                color: opt["correct"] ? Colors.green : null,
                fontWeight: opt["correct"] ? FontWeight.bold : null,
              ),
            );
          }).toList(),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
