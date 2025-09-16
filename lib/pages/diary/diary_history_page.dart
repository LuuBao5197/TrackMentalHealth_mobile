import 'package:flutter/material.dart';
import '../../core/constants/diary_api.dart';
import 'package:intl/intl.dart';

class DiaryHistoryPage extends StatefulWidget {
  const DiaryHistoryPage({super.key});

  @override
  State<DiaryHistoryPage> createState() => _DiaryHistoryPageState();
}

class _DiaryHistoryPageState extends State<DiaryHistoryPage> {
  List<dynamic> diaries = [];
  Map<String, dynamic>? editingDiary;
  String updatedContent = '';

  @override
  void initState() {
    super.initState();
    fetchDiaries();
  }

  Future<void> fetchDiaries() async {
    try {
      final data = await DiaryApi.getDiaries();
      setState(() {
        diaries = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load diary entries')),
      );
    }
  }

  void handleEditClick(Map<String, dynamic> diary) {
    final diaryDate = DateTime.parse(diary['date']);
    final today = DateTime.now();

    final isSameDay = diaryDate.year == today.year &&
        diaryDate.month == today.month &&
        diaryDate.day == today.day;

    if (!isSameDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only edit today\'s diary entry.')),
      );
      return;
    }

    setState(() {
      editingDiary = diary;
      updatedContent = diary['content'];
    });
  }

  Future<void> handleSave() async {
    if (editingDiary == null) return;
    try {
      await DiaryApi.updateDiary(
        editingDiary!['id'],
        updatedContent,
        editingDiary!['date'],
      );

      setState(() {
        diaries = diaries.map((d) {
          if (d['id'] == editingDiary!['id']) {
            return {...d, 'content': updatedContent};
          }
          return d;
        }).toList();
        editingDiary = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Update failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📖 Diary History'),
      ),
      body: diaries.isEmpty
          ? const Center(child: Text('No diary entries yet.'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: diaries.length,
        itemBuilder: (context, index) {
          final diary = diaries[index];

          final dateStr = diary['date']?.toString() ?? '';
          DateTime diaryDate;
          try {
            diaryDate = DateTime.parse(dateStr);
          } catch (_) {
            diaryDate = DateTime.now();
          }

          final content = diary['content']?.toString() ?? '';

          final today = DateTime.now();
          final isSameDay = diaryDate.year == today.year &&
              diaryDate.month == today.month &&
              diaryDate.day == today.day;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                DateFormat('dd/MM/yyyy').format(diaryDate),
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              subtitle: Text(
                content.length > 120 ? '${content.substring(0, 120)}...' : content,
              ),
              trailing: isSameDay
                  ? IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => handleEditClick(diary),
              )
                  : null,
            ),
          );
        },
      ),
      floatingActionButton: editingDiary != null
          ? FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.save),
        onPressed: handleSave,
      )
          : null,
      bottomSheet: editingDiary != null
          ? Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '📝 Edit Diary Entry',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter new content...',
              ),
              controller: TextEditingController(text: updatedContent)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: updatedContent.length),
                ),
              onChanged: (value) => updatedContent = value,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: handleSave,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      )
          : null,
    );
  }
}
