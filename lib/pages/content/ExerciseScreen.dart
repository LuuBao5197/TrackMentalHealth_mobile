import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import 'detail/ExerciseDetailScreen.dart';
 // 👈 import ApiConstants

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  List<dynamic> exercises = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchExercises();
  }

  Future<void> fetchExercises() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.getExercises)); // 👈 dùng URL từ ApiConstants
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final filtered = data.where((ex) =>
        ex['status'] == true || ex['status'] == 'true').toList();

        setState(() {
          exercises = filtered;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load exercises');
      }
    } catch (e) {
      print('❌ Error loading exercises: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildExerciseCard(dynamic ex) {
    final String imageUrl = (ex['photo'] != null && ex['photo'].toString().isNotEmpty)
        ? (ex['photo'].toString().startsWith('http')
        ? ex['photo']
        : 'http://${ApiConstants.ipLocal}:9999/uploads/${ex['photo']}') // 👈 dùng ipLocal từ ApiConstants
        : 'https://via.placeholder.com/400x200.png?text=Exercise';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseDetailScreen(exerciseId: ex['id']),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ex['mediaType'] ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ex['title'] != null && ex['title'].toString().length > 40
                        ? '${ex['title'].toString().substring(0, 40)}...'
                        : ex['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ex['instruction'] != null && ex['instruction'].toString().length > 50
                        ? '${ex['instruction'].toString().substring(0, 50)}...'
                        : ex['instruction'] ?? '',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise List'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : exercises.isEmpty
          ? const Center(child: Text('No exercises available.'))
          : ListView.builder(
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          return buildExerciseCard(exercises[index]);
        },
      ),
    );
  }
}
