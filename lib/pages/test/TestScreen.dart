import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  int _pageSize = 2;
  int _totalPages = 1;
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  Future<void> fetchTests({int page = 1, String search = ''}) async {
    setState(() => _loading = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.getTests}?page=$page&size=$_pageSize&search=$search'),
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
      print(e);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Lỗi khi tải dữ liệu')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTests(page: _page);
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
    return Scaffold(
      appBar: AppBar(title: const Text('🧠 Mental Health Tests')),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            _loading
                ? const Expanded(child: Center(child: CircularProgressIndicator()))
                : _tests.isEmpty
                ? const Expanded(child: Center(child: Text('Không có bài test nào')))
                : Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _tests.length,
                itemBuilder: (context, index) {
                  final test = _tests[index];
                  return Card(
                    elevation: 3,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            test.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            test.description.length > 100
                                ? '${test.description.substring(0, 100)}...'
                                : test.description,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _handleDoTest(test.id),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Do Test'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
                    onPressed: _page > 1 ? () => _onPageChange(_page - 1) : null,
                  ),
                  Text('Page $_page of $_totalPages'),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: _page < _totalPages ? () => _onPageChange(_page + 1) : null,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
