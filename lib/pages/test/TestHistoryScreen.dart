import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:trackmentalhealth/core/constants/api_constants.dart';
import 'TestAttemptDetailScreen.dart';

class TestHistoryScreen extends StatefulWidget {
  final int userId;

  const TestHistoryScreen({super.key, required this.userId});

  @override
  State<TestHistoryScreen> createState() => _TestHistoryScreenState();
}

class _TestHistoryScreenState extends State<TestHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _history = [];

  // Pagination
  int _currentPage = 1;
  final int _rowsPerPage = 5;

  // Columns visibility
  bool _showStartedAt = true;
  bool _showCompletedAt = true;
  bool _showTotalScore = true;

  // Sorting
  int? _sortColumnIndex;
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/test/getTestHistory/${widget.userId}"),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (!mounted) return;
        setState(() => _history = data);
      } else {
        if (!mounted) return;
        setState(() => _error = "Failed to load test history.");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = "Error: $e");
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _sort<T>(Comparable<T> Function(dynamic d) getField, int columnIndex, bool ascending) {
    _history.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending ? Comparable.compare(aValue, bValue) : Comparable.compare(bValue, aValue);
    });
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
    });
  }

  List<dynamic> get _paginatedHistory {
    final start = (_currentPage - 1) * _rowsPerPage;
    final end = start + _rowsPerPage;
    return _history.sublist(start, end > _history.length ? _history.length : end);
  }

  void _nextPage() {
    if (_currentPage * _rowsPerPage < _history.length) setState(() => _currentPage++);
  }

  void _previousPage() {
    if (_currentPage > 1) setState(() => _currentPage--);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final bgColor = isDarkMode ? Colors.grey.shade900 : Colors.white;
    final headerColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final buttonColor = isDarkMode ? Colors.teal.shade700 : Colors.teal;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: bgColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("📜 Test History"),
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 3,
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                setState(() {
                  if (value == "started") _showStartedAt = !_showStartedAt;
                  if (value == "completed") _showCompletedAt = !_showCompletedAt;
                  if (value == "score") _showTotalScore = !_showTotalScore;
                });
              },
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                  value: "started",
                  checked: _showStartedAt,
                  child: const Text("Show Started At"),
                ),
                CheckedPopupMenuItem(
                  value: "completed",
                  checked: _showCompletedAt,
                  child: const Text("Show Completed At"),
                ),
                CheckedPopupMenuItem(
                  value: "score",
                  checked: _showTotalScore,
                  child: const Text("Show Total Score"),
                ),
              ],
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!, style: TextStyle(color: Colors.red)))
            : Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _isAscending,
                    headingRowColor: WidgetStateProperty.all(headerColor),
                    dataRowColor: WidgetStateProperty.resolveWith(
                            (states) => isDarkMode ? Colors.grey.shade900 : Colors.white),
                    columns: [
                      DataColumn(label: Text("#", style: TextStyle(color: textColor))),
                      DataColumn(
                        label: Text("Test Title", style: TextStyle(color: textColor)),
                        onSort: (i, asc) => _sort<String>((d) => d["testTitle"] ?? "", i, asc),
                      ),
                      if (_showStartedAt)
                        DataColumn(
                          label: Text("Started At", style: TextStyle(color: textColor)),
                          onSort: (i, asc) => _sort<DateTime>(
                                  (d) => d["startedAt"] != null
                                  ? DateTime.parse(d["startedAt"])
                                  : DateTime.fromMillisecondsSinceEpoch(0),
                              i,
                              asc),
                        ),
                      if (_showCompletedAt)
                        DataColumn(
                          label: Text("Completed At", style: TextStyle(color: textColor)),
                          onSort: (i, asc) => _sort<DateTime>(
                                  (d) => d["completedAt"] != null
                                  ? DateTime.parse(d["completedAt"])
                                  : DateTime.fromMillisecondsSinceEpoch(0),
                              i,
                              asc),
                        ),
                      if (_showTotalScore)
                        DataColumn(
                          label: Text("Total Score", style: TextStyle(color: textColor)),
                          onSort: (i, asc) => _sort<num>((d) => d["totalScore"] ?? 0, i, asc),
                        ),
                      DataColumn(label: Text("Action", style: TextStyle(color: textColor))),
                    ],
                    rows: _paginatedHistory.isNotEmpty
                        ? _paginatedHistory.asMap().entries.map((entry) {
                      final idx = entry.key + (_currentPage - 1) * _rowsPerPage;
                      final item = entry.value;
                      return DataRow(
                        cells: [
                          DataCell(Text("${idx + 1}", style: TextStyle(color: textColor))),
                          DataCell(Text(item["testTitle"] ?? "-", style: TextStyle(color: textColor))),
                          if (_showStartedAt)
                            DataCell(Text(
                                item["startedAt"] != null
                                    ? DateFormat('dd/MM/yyyy HH:mm')
                                    .format(DateTime.parse(item["startedAt"]).toLocal())
                                    : "-",
                                style: TextStyle(color: textColor))),
                          if (_showCompletedAt)
                            DataCell(Text(
                                item["completedAt"] != null
                                    ? DateFormat('dd/MM/yyyy HH:mm')
                                    .format(DateTime.parse(item["completedAt"]).toLocal())
                                    : "-",
                                style: TextStyle(color: textColor))),
                          if (_showTotalScore)
                            DataCell(Text("${item["totalScore"] ?? "-"}",
                                style: TextStyle(color: textColor))),
                          DataCell(
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TestAttemptDetailScreen(
                                      attemptId: item["attemptId"],
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                              child: const Text("View Detail"),
                            ),
                          ),
                        ],
                      );
                    }).toList()
                        : [
                      DataRow(cells: [
                        DataCell(Text("-", style: TextStyle(color: textColor))),
                        DataCell(Text("No test history found.", style: TextStyle(color: textColor))),
                        DataCell(Text("-", style: TextStyle(color: textColor))),
                        DataCell(Text("-", style: TextStyle(color: textColor))),
                        DataCell(Text("-", style: TextStyle(color: textColor))),
                        DataCell(Text("-", style: TextStyle(color: textColor))),
                      ])
                    ],
                  ),
                ),
              ),
            ),
            if (_history.length > _rowsPerPage)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: textColor),
                      onPressed: _previousPage,
                    ),
                    Text("Page $_currentPage of ${(_history.length / _rowsPerPage).ceil()}",
                        style: TextStyle(color: textColor)),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios, color: textColor),
                      onPressed: _nextPage,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

