import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'package:trackmentalhealth/core/constants/api_constants.dart';
import 'detail/LessonDetailScreen.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  List lessons = [];
  Map<int, int> progressMap = {};
  int currentPage = 1;
  final int lessonsPerPage = 6;

  String? userId;
  String? token;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadTokenAndUser();
  }

  Future<void> _loadTokenAndUser() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('token') ?? '';
    if (storedToken.isNotEmpty) {
      try {
        final decoded = JwtDecoder.decode(storedToken);
        setState(() {
          token = storedToken;
          userId = decoded['userId'].toString();
          isLoggedIn = true;
        });
        fetchLessons(); // Gọi sau khi có token + userId
      } catch (e) {
        print('❌ Token không hợp lệ: $e');
      }
    } else {
      print('❌ Không tìm thấy token');
    }
  }

  Future<void> fetchLessons() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.getLessons),
        headers: token != null
            ? {
          'Authorization': 'Bearer $token',
        }
            : {},
      );

      print("📡 Lessons API status: ${response.statusCode}");
      print("📡 Lessons API body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final activeLessons = data
            .where((lesson) =>
        lesson['status'] == true || lesson['status'] == 'true')
            .toList();

        setState(() {
          lessons = activeLessons;
        });

        // Tạo một map tạm để gom progress
        final newProgressMap = <int, int>{};
        for (var lesson in activeLessons) {
          final lessonId = lesson['id'];
          final progress = await fetchProgressPercent(lessonId);
          newProgressMap[lessonId] = progress;
        }

        // Update progressMap một lần
        setState(() {
          progressMap = newProgressMap;
        });
      } else {
        print("❌ Failed to load lessons: ${response.body}");
      }
    } catch (e) {
      print("❌ Error fetchLessons: $e");
    }
  }

  Future<int> fetchProgressPercent(int lessonId) async {
    if (userId == null || token == null) return 0;

    try {
      final url =
          '${ApiConstants.baseUrl}/user/$userId/lesson/$lessonId/progress-percent';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Progress API [$lessonId] status: ${response.statusCode}');
      print('📡 Progress API [$lessonId] body: ${response.body}');

      if (response.statusCode == 200) {
        final body = json.decode(response.body);

        if (body is int) {
          return body;
        } else if (body is double) {
          return body.round(); // ví dụ 100.0 -> 100
        } else if (body is String) {
          return int.tryParse(body) ?? double.tryParse(body)?.round() ?? 0;
        } else if (body is Map) {
          if (body.containsKey("progressPercent")) {
            return (body["progressPercent"] as num).round();
          }
          if (body.containsKey("percent")) {
            return (body["percent"] as num).round();
          }
        }
        return 0;
      } else {
        print('❌ Failed to fetch progress for lesson $lessonId: ${response.body}');
        return 0;
      }
    } catch (e) {
      print('❌ Error fetching progress for lesson $lessonId: $e');
      return 0;
    }
  }


  List get currentLessons {
    final start = (currentPage - 1) * lessonsPerPage;
    final end = start + lessonsPerPage;
    return lessons.sublist(start, end.clamp(0, lessons.length));
  }

  void handleLessonTap(int lessonId) {
    if (!isLoggedIn) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('You are not logged in'),
          content: const Text('Please log in to access this lesson.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('Log In'),
            ),
          ],
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LessonDetailScreen(lessonId: lessonId),
        ),
      );
    }
  }

  Widget buildCircularProgress(int progress) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress / 100,
            strokeWidth: 6,
            backgroundColor: Colors.grey.shade300,
            color: Colors.blue,
          ),
          Text('$progress%'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (lessons.length / lessonsPerPage).ceil();

    return Scaffold(
      appBar: AppBar(title: const Text('Lessons')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text("Explore engaging lessons",
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.count(
                crossAxisCount:
                MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3 / 4,
                children: currentLessons.map((lesson) {
                  final progress = progressMap[lesson['id']] ?? 0;
                  final imageUrl = (lesson['photo'] ?? "").startsWith('http')
                      ? lesson['photo']
                      : 'https://via.placeholder.com/300x180';

                  return GestureDetector(
                    onTap: () => handleLessonTap(lesson['id']),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12)),
                                child: Image.network(
                                  imageUrl,
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lesson['title'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      lesson['description'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                      const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: buildCircularProgress(progress),
                          )
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (totalPages > 1)
              Wrap(
                spacing: 8,
                children: List.generate(totalPages, (i) {
                  final index = i + 1;
                  return ElevatedButton(
                    onPressed: () => setState(() => currentPage = index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      currentPage == index ? Colors.teal : Colors.grey,
                    ),
                    child: Text("$index"),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}
