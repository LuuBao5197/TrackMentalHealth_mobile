import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:trackmentalhealth/core/constants/api_constants.dart';
import '../../core/constants/mental_alert_box.dart';
import '../../core/constants/mood_api.dart'; // your API file

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

      // ======= DATA ANALYSIS (similar to React version) =======
      final moodLabels = {
        1: 'Very bad',
        2: 'Bad',
        3: 'Normal',
        4: 'Happy',
        5: 'Very happy',
      };

      final levelCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (var entry in filtered) {
        final level = entry.value as int;
        if (levelCounts.containsKey(level)) {
          levelCounts[level] = levelCounts[level]! + 1;
        }
      }

      // Split into 2 halves to calculate trend
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
        trendDescription = "Mood tends to improve (lower at the start, higher at the end).";
      } else if (diff < -0.3) {
        trendDescription = "Mood tends to decline (higher at the start, lower at the end).";
      } else {
        trendDescription = "Mood is stable, no significant fluctuations.";
      }

      final entries = filtered.map((e) {
        final date = DateTime.parse(e.key);
        final level = e.value as int;
        return "Date ${DateFormat('dd/MM').format(date)}: ${moodLabels[level] ?? 'Unknown'} (level $level)";
      }).join("\n");

      final aiPrompt = """
Here is the user’s mood statistics for the past $filterRange days.
Mood levels: 
1: Very bad
2: Bad
3: Normal
4: Happy
5: Very happy

--- Statistics ---
Days at level 1 (Very bad): ${levelCounts[1]}
Days at level 2 (Bad): ${levelCounts[2]}
Days at level 3 (Normal): ${levelCounts[3]}
Days at level 4 (Happy): ${levelCounts[4]}
Days at level 5 (Very happy): ${levelCounts[5]}

--- Trend ---
Average mood level (first half): ${avgFirstHalf.toStringAsFixed(2)}
Average mood level (second half): ${avgSecondHalf.toStringAsFixed(2)}
Overall trend: $trendDescription

--- Daily details ---
$entries

==> Based on this information, briefly analyze the mental health during this period.
- If moods are mostly positive (4–5) and trending upward, conclude mental state is improving.
- If moods are declining or mostly low, give an appropriate remark.
- If stable, conclude stability.
Only answer briefly in 1–2 sentences, no need to repeat details.
""";

      // ======= CALL AI API =======
      final uri = Uri.parse("http://${ApiConstants.ipLocal}:9999/api/analyze-mood");
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"prompt": aiPrompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          aiAnalysis = data['result'] ?? 'No AI response.';
        });
      } else {
        setState(() {
          aiAnalysis = 'Could not connect to AI at the moment.';
        });
      }
    } catch (e) {
      setState(() {
        aiAnalysis = 'Could not fetch mood statistics.';
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
          const SnackBar(content: Text('Error loading mood history')),
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
      return const Center(child: Text('No chart data available'));
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
            checkToShowHorizontalLine: (value) => value % 1 == 0, // only whole-number grid lines
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

                  const moodLabels = ['Very bad', 'Bad', 'Normal', 'Happy', 'Very happy'];
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
                interval: 1, // ✅ only show whole numbers
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
      return const Center(child: Text('No mood history available'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Mood')),
          DataColumn(label: Text('Note')),
          DataColumn(label: Text('AI Suggestion')),
        ],
        rows: pagedMoods.map<DataRow>((mood) {
          final dateStr = mood['date'];
          final date = (dateStr != null && dateStr.isNotEmpty)
              ? DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr))
              : 'Unknown';
          final moodLevel = mood['moodLevel']?['name'] ?? 'Unknown';
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
        title: const Text('Mood History'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Center(
              child: Text(
                '📈 Mood chart over time',
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
                    DropdownMenuItem(value: '7', child: Text('Past 7 days')),
                    DropdownMenuItem(value: '30', child: Text('Past 1 month')),
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
              '📖 Mood history',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
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
                  child: const Text('⬅️ Previous'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Page ${currentPage + 1} / $totalPages'),
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
                  child: const Text('Next ➡️'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
