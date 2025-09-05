import 'package:flutter/material.dart';
import 'LessonScreen.dart';
import 'ArticleScreen.dart';
import 'ExerciseScreen.dart';

class ContentTabScreen extends StatelessWidget {
  const ContentTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: isLandscape
            ? null
            : AppBar(
          automaticallyImplyLeading: false,
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
        body: isLandscape
            ? Row(
          children: [
            // Nội dung bên trái
            const Expanded(
              child: TabBarView(
                children: [
                  LessonScreen(),
                  ArticleScreen(),
                  ExerciseScreen(),
                ],
              ),
            ),

            // Divider
            const VerticalDivider(width: 1),

            // TabBar dạng dọc chỉ có icon
            Container(
              width: 70,
              color: Colors.white,
              child: const IconTabBar(),
            ),
          ],
        )
            : const TabBarView(
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

/// Custom vertical TabBar chỉ hiển thị icon
class IconTabBar extends StatelessWidget {
  const IconTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final TabController controller = DefaultTabController.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTabItem(controller, 0, Icons.school),
            const SizedBox(height: 20),
            _buildTabItem(controller, 1, Icons.article),
            const SizedBox(height: 20),
            _buildTabItem(controller, 2, Icons.fitness_center),
          ],
        );
      },
    );
  }

  Widget _buildTabItem(TabController controller, int index, IconData icon) {
    final bool isSelected = controller.index == index;

    return GestureDetector(
      onTap: () => controller.animateTo(index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? Colors.teal.withOpacity(0.2) : Colors.transparent,
        ),
        child: Icon(
          icon,
          size: 28,
          color: isSelected ? Colors.teal : Colors.grey,
        ),
      ),
    );
  }
}
