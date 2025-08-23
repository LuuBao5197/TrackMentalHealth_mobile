import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackmentalhealth/pages/test/TestHistoryScreen.dart';
import '../../core/constants/api_constants.dart';
import '../../models/test_model.dart';
import 'TestDetailScreen.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});
  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  List<TestModel> _tests = [];
  bool _loading = true;
  int _page = 1;
  int _pageSize = 3;
  int _totalPages = 1;
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    fetchTests(page: _page);
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt("userId");
    setState(() {
      _userId = id;
    });
  }

  Future<void> fetchTests({int page = 1, String search = ''}) async {
    setState(() => _loading = true);
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.getTests}?page=$page&size=$_pageSize&search=$search',
        ),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        List<dynamic> data = jsonData['data'] ?? [];
        _totalPages = jsonData['totalPages'] ?? 1;

        setState(() {
          _tests = data.map((e) => TestModel.fromJson(e)).toList();
        });
      } else {
        throw Exception('Failed to load tests');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi tải dữ liệu')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onPageChange(int newPage) {
    if (newPage >= 1 && newPage <= _totalPages) {
      _page = newPage;
      fetchTests(page: _page, search: _search);
    }
  }

  void _onSearch() {
    _page = 1;
    _search = _searchController.text.trim();
    fetchTests(page: _page, search: _search);
  }

  void _handleDoTest(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TestDetailScreen(testId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Mental Health Tests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_toggle_off),
            tooltip: 'View History',
            onPressed: _userId == null
                ? null
                : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TestHistoryScreen(userId: _userId!),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search box
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by title or description...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _onSearch,
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            _loading
                ? const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
                : _tests.isEmpty
                ? const Expanded(
              child: Center(child: Text('Không có bài test nào')),
            )
                : Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isLandscape =
                      constraints.maxWidth > constraints.maxHeight;

                  return GridView.builder(
                    gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isLandscape ? 3 : 2,
                      childAspectRatio: isLandscape ? 1.2 : 0.8,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _tests.length,
                    itemBuilder: (context, index) {
                      final test = _tests[index];

                      return Card(
                        elevation: 3,
                        shadowColor: isDark
                            ? Colors.black45
                            : Colors.teal.withOpacity(0.3),
                        color: isDark
                            ? Colors.grey.shade900
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade700
                                  : Colors.transparent),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              // Title
                              Row(
                                children: [
                                  Icon(
                                    Icons.assignment_outlined,
                                    size: 18,
                                    color:
                                    isDark ? Colors.tealAccent : Colors.teal,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      test.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Description
                              Tooltip(
                                message: test.description,
                                textStyle: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey.shade800
                                      : Colors.white,
                                  borderRadius:
                                  BorderRadius.circular(6),
                                  border: Border.all(
                                      color: isDark
                                          ? Colors.grey.shade700
                                          : Colors.transparent),
                                ),
                                child: Text(
                                  test.description,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey.shade200
                                        : Colors.black54,
                                    fontSize: 13,
                                  ),
                                  maxLines: isLandscape ? 2 : 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Do Test button
                              if (isLandscape)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _handleDoTest(test.id),
                                    icon: const Icon(
                                      Icons.psychology_alt,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    label: const Text('Do Test'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(30),
                                      ),
                                      shadowColor: isDark
                                          ? Colors.black54
                                          : Colors.teal
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                ),
                              if (!isLandscape) ...[
                                const Spacer(),
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _handleDoTest(test.id),
                                    icon: const Icon(
                                      Icons.psychology_alt,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    label: const Text('Do Test'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(30),
                                      ),
                                      shadowColor: isDark
                                          ? Colors.black54
                                          : Colors.teal
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Pagination
            if (_totalPages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed:
                    _page > 1 ? () => _onPageChange(_page - 1) : null,
                  ),
                  Text(
                    'Page $_page of $_totalPages',
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: _page < _totalPages
                        ? () => _onPageChange(_page + 1)
                        : null,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
