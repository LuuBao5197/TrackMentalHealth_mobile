import 'package:flutter/material.dart';
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BlogDetailScreen()),
          );
        },
        child: const Text('Đi tới bài viết chi tiết'),
      ),
    );
  }
}

class BlogDetailScreen extends StatelessWidget {
  const BlogDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 3,
        shadowColor: Colors.teal.withOpacity(0.3),
        title: Text(
          'Chi tiết bài viết',
          style: TextStyle(
            color: Colors.teal[800],
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.teal[800]),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Đây là nội dung chi tiết bài viết.\nBạn có thể đọc thêm thông tin ở đây...',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
