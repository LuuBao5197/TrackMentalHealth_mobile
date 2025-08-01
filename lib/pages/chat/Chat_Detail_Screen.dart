
import 'package:flutter/material.dart';

class ChatDetailScreen extends StatelessWidget {
  const ChatDetailScreen({super.key});

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
