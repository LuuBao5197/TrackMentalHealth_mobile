import 'package:flutter/material.dart';
import 'LessonScreen.dart';
import 'ArticleScreen.dart';
import 'ExerciseScreen.dart';

class ContentTabScreen extends StatelessWidget {
  const ContentTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Ẩn nút quay lại nếu có
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.teal,
            tabs: [
              Tab(icon: Icon(Icons.school), text: 'Lessons'),
              Tab(icon: Icon(Icons.article), text: 'Articles'),
              Tab(icon: Icon(Icons.fitness_center), text: 'Exercises'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            LessonScreen(),
            ArticleScreen(),
            ExerciseScreen(),
          ],
        ),
      ),
    );
  }
}
