import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:timeago/timeago.dart' as timeago;

class ArticleDetailScreen extends StatefulWidget {
  final int articleId;

  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  Map<String, dynamic>? article;
  List<Map<String, dynamic>> comments = [];
  Map<String, String> usernames = {};
  String? userId;
  String commentContent = '';
  bool isLoading = true;
  bool isPosting = false;

  @override
  void initState() {
    super.initState();
    _fetchArticle();
    _fetchComments();
    _decodeToken();
  }

  Future<void> _decodeToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isNotEmpty) {
      try {
        final decoded = JwtDecoder.decode(token);
        setState(() {
          userId = decoded['userId'].toString();
        });
      } catch (e) {
        print('❌ Token không hợp lệ: $e');
      }
    } else {
      print('❌ Không tìm thấy token');
    }
  }

  Future<void> _fetchArticle() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:9999/api/article/${widget.articleId}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          article = json.decode(response.body);
          isLoading = false;
        });
      } else {
        print('❌ Lỗi khi tải bài viết: ${response.body}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Lỗi: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchComments() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:9999/api/article/${widget.articleId}/comments'),
      );
      if (response.statusCode == 200) {
        setState(() {
          comments = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
        _fetchUsernames();
      } else {
        print('❌ Lỗi khi tải bình luận: ${response.body}');
      }
    } catch (e) {
      print('❌ Lỗi: $e');
    }
  }

  Future<void> _fetchUsernames() async {
    final newUsernames = {...usernames};
    for (final comment in comments) {
      final uid = comment['user']?['id']?.toString() ?? comment['userId']?.toString();
      if (uid != null && !newUsernames.containsKey(uid)) {
        try {
          final response = await http.get(
            Uri.parse('http://10.0.2.2:9999/api/user/$uid'),
          );
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            newUsernames[uid] = data['username'] ?? 'Unknown';
          } else {
            newUsernames[uid] = 'Unknown';
          }
        } catch (e) {
          print('❌ Lỗi khi lấy username cho ID $uid: $e');
          newUsernames[uid] = 'Unknown';
        }
      }
    }
    setState(() {
      usernames = newUsernames;
    });
  }

  Future<void> _postComment() async {
    if (commentContent.trim().isEmpty) return;

    setState(() {
      isPosting = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:9999/api/article/${widget.articleId}/comments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'content': commentContent,
          'userId': userId,
        }),
      );
      if (response.statusCode == 200) {
        setState(() {
          commentContent = '';
        });
        await _fetchComments();
      } else {
        _showErrorDialog(
          title: 'Bình luận không hợp lệ',
          message: json.decode(response.body)['message'] ?? 'Lỗi không xác định',
        );
      }
    } catch (e) {
      _showErrorDialog(
        title: 'Lỗi server',
        message: e.toString(),
      );
    } finally {
      setState(() {
        isPosting = false;
      });
    }
  }

  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getRelativeTime(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return timeago.format(date, locale: 'en');
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Article Detail')),
        body: const Center(
          child: SpinKitCircle(
            color: Colors.blue,
            size: 50.0,
          ),
        ),
      );
    }

    if (article == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Article Detail')),
        body: const Center(
          child: Text(
            'Không thể tải bài viết.',
            style: TextStyle(fontSize: 24, color: Colors.red),
          ),
        ),
      );
    }

    final imageUrl = (article!['photo'] ?? '').startsWith('http')
        ? article!['photo']
        : article!['photo'] != null && article!['photo'].isNotEmpty
        ? 'http://10.0.2.2:9999/uploads/${article!['photo']}'
        : 'https://via.placeholder.com/300x180';

    return Scaffold(
      appBar: AppBar(
        title: Text(article!['title'] ?? 'Article Detail'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bookmark, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Article Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              article!['title'] ?? '',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Georgia',
              ),
            ),
            const SizedBox(height: 12),
            Image.network(
              imageUrl,
              width: double.infinity,
              height: 350,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Text(
                'Không thể tải hình ảnh',
                style: TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              article!['content'] ?? '',
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'Georgia',
                height: 1.8,
              ),
            ),
            const Divider(height: 40),
            const Text(
              '💬 Comments',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            userId != null
                ? Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Write your comment...',
                  ),
                  maxLines: 3,
                  onChanged: (value) => setState(() {
                    commentContent = value;
                  }),
                  controller: TextEditingController(text: commentContent),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: isPosting ? null : _postComment,
                  child: Text(isPosting ? 'Posting...' : 'Post Comment'),
                ),
              ],
            )
                : GestureDetector(
              onTap: () {
                // Navigate to login screen
                Navigator.pushNamed(context, '/login'); // Adjust route as needed
              },
              child: const Text(
                '🔒 Please log in to comment',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 16),
            comments.isNotEmpty
                ? Column(
              children: comments.map((comment) {
                final uid = comment['user']?['id']?.toString() ?? comment['userId']?.toString();
                final username = usernames[uid] ?? 'Loading...';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        comment['content'] ?? '',
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      Text(
                        _getRelativeTime(comment['createdAt']),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const Divider(),
                    ],
                  ),
                );
              }).toList(),
            )
                : const Text(
              'No comments yet.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}