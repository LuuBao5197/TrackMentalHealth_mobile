import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackmentalhealth/core/constants/api_constants.dart';
import 'package:trackmentalhealth/pages/quiz/DoQuizPage.dart';
import '../../models/Quiz.dart';
import 'QuizAttemptListPage.dart';

// ================== ENTITY ==================
class PaginatedQuizResponse {
  final List<Quiz> data;
  final int totalPages;

  PaginatedQuizResponse({required this.data, required this.totalPages});

  factory PaginatedQuizResponse.fromJson(Map<String, dynamic> json) {
    var list = (json['data'] as List).map((q) => Quiz.fromJson(q)).toList();
    return PaginatedQuizResponse(
      data: list,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}

// ================== API SERVICE ==================
Future<PaginatedQuizResponse> fetchQuizzes(int page, String search) async {
  final response = await http.get(
    Uri.parse(
        "${ApiConstants.baseUrl}/quizzes?page=$page&size=4&search=$search"),
  );
  if (response.statusCode == 200) {
    return PaginatedQuizResponse.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to load quizzes');
  }
}

// ================== UI ==================
class QuizListForUserPage extends StatefulWidget {
  const QuizListForUserPage({super.key});

  @override
  State<QuizListForUserPage> createState() => _QuizListForUserPageState();
}

class _QuizListForUserPageState extends State<QuizListForUserPage> {
  List<Quiz> _quizzes = [];
  bool _loading = true;
  int _page = 1;
  int _totalPages = 1;
  String _search = '';
  final TextEditingController _searchController = TextEditingController();
  int? _userId;
  @override
  void initState() {
    super.initState();
    _loadUserId();
    _fetchData();

  }
  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt("userId");
    setState(() {
      _userId = id;
    });
  }


  Future<void> _fetchData() async {
    setState(() => _loading = true);

    try {
      final result = await fetchQuizzes(_page, _search);
      setState(() {
        _quizzes = result.data;
        _totalPages = result.totalPages;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch() {
    _page = 1;
    _search = _searchController.text.trim();
    _fetchData();
  }

  void _onPageChange(int newPage) {
    if (newPage >= 1 && newPage <= _totalPages) {
      _page = newPage;
      _fetchData();
    }
  }

  void _handleDoQuiz(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DoQuizPage(quizId: id)),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text("🧠 Mental Health Quizzes"),
        actions: [
          IconButton(
            tooltip: "My Quiz History",
            icon: const Icon(Icons.history),
            onPressed: _userId == null
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizAttemptListPage(userId: _userId!),
                  // 👆 userId lấy từ redux hoặc provider của bạn
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
            // Search
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
                : _quizzes.isEmpty
                ? const Expanded(
              child: Center(child: Text("No quizzes found")),
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
                    itemCount: _quizzes.length,
                    itemBuilder: (context, index) {
                      final quiz = _quizzes[index];
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
                                    Icons.quiz_outlined,
                                    size: 18,
                                    color: isDark
                                        ? Colors.tealAccent
                                        : Colors.teal,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      quiz.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow:
                                      TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Description (render HTML, tooltip cho nội dung đầy đủ)
                              Tooltip(
                                message: quiz.description,
                                child: SizedBox(
                                  height: 60,
                                  child: SingleChildScrollView(
                                    child: Html(
                                      data: quiz.description,
                                      style: {
                                        "body": Style(
                                          margin: Margins.zero,
                                          padding: HtmlPaddings.zero,
                                          fontSize: FontSize.small,
                                          color: isDark
                                              ? Colors.grey.shade300
                                              : Colors.black54,
                                        ),
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Do Quiz button
                              if (isLandscape)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _handleDoQuiz(quiz.id),
                                    icon: const Icon(
                                      Icons.edit,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    label: const Text("Do Quiz"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6),
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      shape:
                                      RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(
                                            30),
                                      ),
                                    ),
                                  ),
                                ),
                              if (!isLandscape) ...[
                                const Spacer(),
                                Align(
                                  alignment:
                                  Alignment.bottomCenter,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _handleDoQuiz(quiz.id),
                                    icon: const Icon(
                                      Icons.edit,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    label: const Text("Do Quiz"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6),
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      shape:
                                      RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(
                                            30),
                                      ),
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
