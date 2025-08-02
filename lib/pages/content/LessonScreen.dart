import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  final bool isLoggedIn = true; // 👈 Giả lập trạng thái đăng nhập

  @override
  void initState() {
    super.initState();
    fetchLessons();
  }

  Future<void> fetchLessons() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:9999/api/lesson'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final activeLessons = data.where((lesson) =>
        lesson['status'] == true || lesson['status'] == 'true').toList();

        setState(() {
          lessons = activeLessons;
          for (var lesson in activeLessons) {
            progressMap[lesson['id']] = 12; // 👈 Tạm thời gán cố định
          }
        });
      } else {
        print("Failed to load lessons: ${response.body}");
      }
    } catch (e) {
      print("Error: $e");
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
                // Navigate to login page
              },
              child: const Text('Log In'),
            ),
          ],
        ),
      );
    } else {
      print("Go to lesson $lessonId");
      // Navigate to lesson detail
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
            const Text("Explore engaging lessons", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      lesson['description'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13),
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
                      backgroundColor: currentPage == index ? Colors.teal : Colors.grey,
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
