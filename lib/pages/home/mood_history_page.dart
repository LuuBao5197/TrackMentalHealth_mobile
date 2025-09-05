import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/mental_alert_box.dart';
import '../../core/constants/mood_api.dart'; // file api của bạn

class MoodHistoryPage extends StatefulWidget {
  const MoodHistoryPage({super.key});

  @override
  State<MoodHistoryPage> createState() => _MoodHistoryPageState();
}

class _MoodHistoryPageState extends State<MoodHistoryPage> {
  List<MapEntry<String, dynamic>> chartData = [];
  String aiAnalysis = '';
  String filterRange = '7';

  List<dynamic> pagedMoods = [];
  int currentPage = 0;
  int totalPages = 1;
  final int pageSize = 5;

  bool isLoadingChart = true;
  bool isLoadingPaged = true;

  @override
  void initState() {
    super.initState();
    fetchChartData();
    fetchPagedMoods();
  }

  Future<void> fetchChartData() async {
    setState(() {
      isLoadingChart = true;
      aiAnalysis = '';
    });

    try {
      final raw = await getMoodStatistics(); // Map<String, dynamic> { "2025-08-10": 3, ... }
      final now = DateTime.now();
      final days = filterRange == '7' ? 7 : 30;

      final filtered = raw.entries.where((e) {
        final date = DateTime.parse(e.key);
        return !date.isBefore(now.subtract(Duration(days: days)));
      }).toList();

      filtered.sort((a, b) => DateTime.parse(a.key).compareTo(DateTime.parse(b.key)));

      setState(() {
        chartData = filtered;
      });

      // ======= PHÂN TÍCH SỐ LIỆU NHƯ REACT =======
      final moodLabels = {
        1: 'Rất tệ',
        2: 'Tệ',
        3: 'Bình thường',
        4: 'Vui',
        5: 'Rất vui',
      };

      final levelCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (var entry in filtered) {
        final level = entry.value as int;
        if (levelCounts.containsKey(level)) {
          levelCounts[level] = levelCounts[level]! + 1;
        }
      }

      // Chia làm 2 nửa để tính xu hướng
      final sortedByDate = filtered.map((e) {
        return {
          "date": DateTime.parse(e.key),
          "level": e.value as int,
        };
      }).toList();

      final half = (sortedByDate.length / 2).floor();
      final firstHalf = sortedByDate.sublist(0, half);
      final secondHalf = sortedByDate.sublist(half);

      double avg(List<Map<String, dynamic>> list) {
        if (list.isEmpty) return 0;
        return list.fold(0, (sum, e) => sum + (e["level"] as int)) / list.length;
      }

      final avgFirstHalf = avg(firstHalf);
      final avgSecondHalf = avg(secondHalf);

      String trendDescription;
      final diff = avgSecondHalf - avgFirstHalf;
      if (diff > 0.3) {
        trendDescription = "Cảm xúc có xu hướng tăng dần (đầu kỳ thấp, cuối kỳ cao).";
      } else if (diff < -0.3) {
        trendDescription = "Cảm xúc có xu hướng giảm dần (đầu kỳ cao, cuối kỳ thấp).";
      } else {
        trendDescription = "Cảm xúc ổn định, không có nhiều biến động rõ rệt.";
      }

      final entries = filtered.map((e) {
        final date = DateTime.parse(e.key);
        final level = e.value as int;
        return "Ngày ${DateFormat('dd/MM').format(date)}: ${moodLabels[level] ?? 'Không rõ'} (mức $level)";
      }).join("\n");

      final aiPrompt = """
Dưới đây là thống kê cảm xúc của người dùng trong $filterRange ngày qua.
Mức độ cảm xúc: 
1: Rất tệ
2: Tệ
3: Bình thường
4: Vui
5: Rất vui

--- Thống kê ---
Số ngày mức 1 (Rất tệ): ${levelCounts[1]}
Số ngày mức 2 (Tệ): ${levelCounts[2]}
Số ngày mức 3 (Bình thường): ${levelCounts[3]}
Số ngày mức 4 (Vui): ${levelCounts[4]}
Số ngày mức 5 (Rất vui): ${levelCounts[5]}

--- Diễn biến ---
Mức cảm xúc trung bình nửa đầu: ${avgFirstHalf.toStringAsFixed(2)}
Mức cảm xúc trung bình nửa cuối: ${avgSecondHalf.toStringAsFixed(2)}
Xu hướng tổng thể: $trendDescription

--- Chi tiết từng ngày ---
$entries

==> Dựa trên các thông tin trên, hãy phân tích ngắn gọn sức khỏe tinh thần trong giai đoạn này.
- Nếu cảm xúc chủ yếu tích cực (4–5) và có xu hướng tăng, hãy nhận định là tinh thần cải thiện.
- Nếu cảm xúc giảm hoặc có nhiều mức thấp, hãy đưa ra nhận xét phù hợp.
- Nếu ổn định, kết luận là ổn định.
Chỉ cần trả lời ngắn gọn trong 1–2 câu, không cần liệt kê lại chi tiết.
""";

      // ======= GỌI API AI =======
      final uri = Uri.parse("http://172.16.2.28:9999/api/analyze-mood");
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"prompt": aiPrompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          aiAnalysis = data['result'] ?? 'Không có phản hồi AI.';
        });
      } else {
        setState(() {
          aiAnalysis = 'Không thể kết nối AI lúc này.';
        });
      }
    } catch (e) {
      setState(() {
        aiAnalysis = 'Không thể lấy dữ liệu thống kê.';
        chartData = [];
      });
    } finally {
      setState(() {
        isLoadingChart = false;
      });
    }
  }


  Future<void> fetchPagedMoods() async {
    setState(() {
      isLoadingPaged = true;
    });

    try {
      final res = await getMyMoodsPaged(page: currentPage, size: pageSize);
      setState(() {
        pagedMoods = res['moods'] ?? [];
        totalPages = res['totalPages'] ?? 1;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi tải lịch sử cảm xúc')),
        );
      }
    } finally {
      setState(() {
        isLoadingPaged = false;
      });
    }
  }

  Widget buildChart() {
    if (isLoadingChart) {
      return const Center(child: CircularProgressIndicator());
    }
    if (chartData.isEmpty) {
      return const Center(child: Text('Không có dữ liệu biểu đồ'));
    }

    final spots = chartData.asMap().entries.map((entry) {
      final idx = entry.key.toDouble();
      final moodLevel = entry.value.value;
      return FlSpot(idx, (moodLevel as num).toDouble());
    }).toList();

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          minY: 1,
          maxY: 5,
          gridData: FlGridData(
            show: true,
            checkToShowHorizontalLine: (value) => value % 1 == 0, // chỉ dòng ngang nguyên
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
                interval: 1,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < chartData.length) {
                    final date = DateTime.parse(chartData[idx].key);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('dd/MM').format(date),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value % 1 != 0) return const SizedBox.shrink();

                  const moodLabels = ['Rất tệ', 'Tệ', 'Bình thường', 'Vui', 'Rất vui'];
                  final idx = value.toInt() - 1;
                  if (idx >= 0 && idx < moodLabels.length) {
                    return Text(moodLabels[idx], style: const TextStyle(fontSize: 10));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1, // ✅ chỉ hiện số nguyên
                getTitlesWidget: (value, meta) {
                  if (value % 1 != 0) return const SizedBox.shrink();
                  return Text(value.toInt().toString());
                },
              ),
            ),
          ),

          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPagedTable() {
    if (isLoadingPaged) {
      return const Center(child: CircularProgressIndicator());
    }
    if (pagedMoods.isEmpty) {
      return const Center(child: Text('Không có lịch sử cảm xúc'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Ngày')),
          DataColumn(label: Text('Cảm xúc')),
          DataColumn(label: Text('Ghi chú')),
          DataColumn(label: Text('Gợi ý từ AI')),
        ],
        rows: pagedMoods.map<DataRow>((mood) {
          final dateStr = mood['date'];
          final date = (dateStr != null && dateStr.isNotEmpty)
              ? DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr))
              : 'Không rõ';
          final moodLevel = mood['moodLevel']?['name'] ?? 'Không rõ';
          final note = mood['note'] ?? '...';
          final aiSuggestion = mood['aiSuggestion'] ?? '...';

          return DataRow(cells: [
            DataCell(Text(date)),
            DataCell(Text(moodLevel)),
            DataCell(Text(note)),
            DataCell(Text(aiSuggestion)),
          ]);
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử cảm xúc'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Center(
              child: Text(
                '📈 Biểu đồ cảm xúc theo thời gian',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DropdownButton<String>(
                  value: filterRange,
                  items: const [
                    DropdownMenuItem(value: '7', child: Text('7 ngày qua')),
                    DropdownMenuItem(value: '30', child: Text('1 tháng qua')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        filterRange = value;
                      });
                      fetchChartData();
                    }
                  },
                ),
              ],
            ),
            buildChart(),
            const SizedBox(height: 16),
            if (aiAnalysis.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade700),
                ),
                child: Text(aiAnalysis, textAlign: TextAlign.center),
              ),
            const SizedBox(height: 24),
            const Text(
              '📖 Lịch sử cảm xúc',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            MentalAlertBox(),
            const SizedBox(height: 8),
            buildPagedTable(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: currentPage == 0
                      ? null
                      : () {
                    setState(() {
                      currentPage--;
                    });
                    fetchPagedMoods();
                  },
                  child: const Text('⬅️ Trước'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Trang ${currentPage + 1} / $totalPages'),
                ),
                ElevatedButton(
                  onPressed: currentPage >= totalPages - 1
                      ? null
                      : () {
                    setState(() {
                      currentPage++;
                    });
                    fetchPagedMoods();
                  },
                  child: const Text('Tiếp ➡️'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
