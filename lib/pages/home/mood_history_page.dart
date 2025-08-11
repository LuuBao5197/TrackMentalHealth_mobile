import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/mental_alert_box.dart';


class MoodHistoryPage extends StatefulWidget {
  const MoodHistoryPage({super.key});

  @override
  State<MoodHistoryPage> createState() => _MoodHistoryPageState();
}

class _MoodHistoryPageState extends State<MoodHistoryPage> {
  List<MoodData> chartData = [];
  List<dynamic> moodList = [];
  int currentPage = 0;
  final int pageSize = 5;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchChartData();
    fetchPagedMoods();
  }

  Future<String?> getToken() async {
    // TODO: Thay bằng secure storage hoặc shared_preferences
    return 'your_jwt_token_here';
  }

  Future<void> fetchChartData() async {
    final token = await getToken();
    if (token == null) return;

    final url = Uri.parse("http://localhost:9999/api/moods/my/statistics");

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          chartData = data
              .map((item) => MoodData(
            date: DateTime.parse(item['date']),
            level: item['moodLevel'],
          ))
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> fetchPagedMoods() async {
    final token = await getToken();
    if (token == null) return;

    final url = Uri.parse(
        "http://localhost:9999/api/moods/my/page?page=$currentPage&size=$pageSize");

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          moodList = data['content'];
          loading = false;
        });
      }
    } catch (_) {}
  }

  void nextPage() {
    setState(() {
      currentPage += 1;
      loading = true;
    });
    fetchPagedMoods();
  }

  void prevPage() {
    if (currentPage == 0) return;
    setState(() {
      currentPage -= 1;
      loading = true;
    });
    fetchPagedMoods();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch sử cảm xúc"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          await fetchChartData();
          await fetchPagedMoods();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const MentalAlertBox(),

            const SizedBox(height: 16),
            const Text(
              "📈 Biểu đồ cảm xúc",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 200,
              child: charts.TimeSeriesChart(
                [
                  charts.Series<MoodData, DateTime>(
                    id: 'Mood Level',
                    colorFn: (_, __) =>
                    charts.MaterialPalette.blue.shadeDefault,
                    domainFn: (MoodData mood, _) => mood.date,
                    measureFn: (MoodData mood, _) => mood.level,
                    data: chartData,
                  )
                ],
                animate: true,
                dateTimeFactory: const charts.LocalDateTimeFactory(),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              "📋 Lịch sử cảm xúc gần đây",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...moodList.map((mood) => Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.emoji_emotions),
                title: Text(
                    "Mức độ: ${mood['moodLevelName'] ?? 'Không xác định'}"),
                subtitle: Text("Ngày: ${mood['date'] ?? ''}"),
              ),
            )),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: currentPage > 0 ? prevPage : null,
                  child: const Text("⬅ Trang trước"),
                ),
                OutlinedButton(
                  onPressed: moodList.length == pageSize ? nextPage : null,
                  child: const Text("Trang sau ➡"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MoodData {
  final DateTime date;
  final int level;

  MoodData({required this.date, required this.level});
}
