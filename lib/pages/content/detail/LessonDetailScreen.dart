import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:visibility_detector/visibility_detector.dart';

class LessonDetailScreen extends StatefulWidget {
  final int lessonId;

  const LessonDetailScreen({super.key, required this.lessonId});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  Map<String, dynamic>? lesson;
  List<int> completedSteps = [];
  String? userId;

  @override
  void initState() {
    super.initState();
    _fetchLesson();
    _decodeToken();
  }

  void _decodeToken() {
    // Giả lập lấy token từ local storage (có thể dùng shared_preferences)
    const token = 'YOUR_TOKEN_HERE'; // Thay bằng cách lấy token thực tế
    if (token.isNotEmpty) {
      try {
        final decoded = JwtDecoder.decode(token);
        setState(() {
          userId = decoded['userId'].toString();
        });
      } catch (e) {
        print('❌ Token không hợp lệ: $e');
      }
    }
  }

  Future<void> _fetchLesson() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:9999/api/lesson/${widget.lessonId}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          lesson = json.decode(response.body);
        });
        if (userId != null) {
          _fetchProgress();
        }
      } else {
        print('❌ Lỗi khi tải chi tiết bài học: ${response.body}');
      }
    } catch (e) {
      print('❌ Lỗi: $e');
    }
  }

  Future<void> _fetchProgress() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://10.0.2.2:9999/api/user/$userId/lesson/${widget.lessonId}/progress',
        ),
      );
      if (response.statusCode == 200) {
        final progressData = json.decode(response.body) as List;
        setState(() {
          completedSteps = progressData
              .where((progress) => progress['step'] != null && progress['step']['id'] != null)
              .map((progress) => progress['step']['id'] as int)
              .toList();
        });
      } else {
        print('❌ Lỗi khi lấy progress: ${response.body}');
      }
    } catch (e) {
      print('❌ Lỗi: $e');
    }
  }

  Future<void> _updateProgress(int stepId) async {
    if (userId == null || completedSteps.contains(stepId)) {
      print('⏩ Step $stepId đã hoàn thành hoặc userId không tồn tại');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:9999/api/user/progress/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'lessonId': widget.lessonId,
          'stepCompleted': stepId,
          'userId': userId,
        }),
      );
      if (response.statusCode == 200) {
        print('✅ Đã cập nhật step $stepId vào progress');
        setState(() {
          completedSteps.add(stepId);
        });
      } else {
        print('❌ Lỗi cập nhật step $stepId: ${response.body}');
      }
    } catch (e) {
      print('❌ Lỗi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (lesson == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Đang tải chi tiết bài học...',
            style: TextStyle(fontSize: 24),
          ),
        ),
      );
    }

    final lessonSteps = (lesson!['lessonSteps'] as List?)
        ?.cast<Map<String, dynamic>>()
        .where((step) => step['id'] != null)
        .toList() ??
        [];

    return Scaffold(
      appBar: AppBar(
        title: Text(lesson!['title'] ?? 'Lesson Detail'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.notifications, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Introduce the lesson',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              lesson!['title'] ?? '',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'Georgia',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lesson!['description'] ?? '',
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'Georgia',
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            // Steps Section
            const Text(
              '📌 Steps in the lesson:',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const Divider(color: Colors.blue),
            lessonSteps.isNotEmpty
                ? Column(
              children: lessonSteps
                  .asMap()
                  .entries
                  .map((entry) {
                final step = entry.value;
                return VisibilityDetector(
                  key: Key('step-${step['id']}'),
                  onVisibilityChanged: (info) {
                    if (info.visibleFraction >= 0.5) {
                      _updateProgress(step['id']);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step ${step['stepNumber']}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontFamily: 'Georgia',
                            height: 1.5,
                          ),
                        ),
                        if (step['mediaType'] == 'photo' && step['mediaUrl'] != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Image.network(
                              step['mediaUrl'],
                              width: MediaQuery.of(context).size.width * 0.7,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Text(
                                'Không thể tải hình ảnh',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        Text(
                          step['content'] ?? 'Nội dung bước ${step['stepNumber']} (cập nhật?)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Georgia',
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              })
                  .toList(),
            )
                : const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'No learning steps right now.',
                style: TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}