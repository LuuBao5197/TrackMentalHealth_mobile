import 'package:flutter/material.dart';
import '../../core/constants/diary_api.dart';
import 'package:http/http.dart' as http;

class WriteDiaryPage extends StatefulWidget {
  const WriteDiaryPage({super.key});

  @override
  State<WriteDiaryPage> createState() => _WriteDiaryPageState();
}

class _WriteDiaryPageState extends State<WriteDiaryPage> {
  final TextEditingController _contentController = TextEditingController();
  bool _loading = false;

  Future<void> _handleSave() async {
    setState(() => _loading = true);
    try {
      http.Response res = await DiaryApi.createDiary(_contentController.text);

      if (res.statusCode == 200 || res.statusCode == 201) {
        _showMessage('📝 Diary entry saved successfully!');
        Navigator.pushReplacementNamed(context, '/history');
      } else {
        _showMessage('❌ Error: ${res.statusCode}');
      }
    } catch (e) {
      _showMessage('❌ An error occurred: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧘‍♀️ Write Mood Diary'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      hintText:
                      'Write down your thoughts and feelings...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Save diary button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _handleSave,
                    icon: const Icon(Icons.save),
                    label: Text(_loading ? 'Saving...' : '💾 Save Diary'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // View diary history button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/history');
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('📜 View Diary History'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
