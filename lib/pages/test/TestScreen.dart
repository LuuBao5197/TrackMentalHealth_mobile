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
  late Future<List<TestModel>> _futureTests;

  Future<List<TestModel>> fetchTests() async {
    final response = await http.get(Uri.parse('${ApiConstants.getTests}'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => TestModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load tests');
    }
  }

  @override
  void initState() {
    super.initState();
    _futureTests = fetchTests();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TestModel>>(
      future: _futureTests,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Lỗi khi tải danh sách bài test'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Không có bài test nào'));
        }

        final tests = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final test = tests[index];
            return Card(
              elevation: 3,
              shadowColor: Colors.teal.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                title: Text(test.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(test.description),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TestDetailScreen(testId: test.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
