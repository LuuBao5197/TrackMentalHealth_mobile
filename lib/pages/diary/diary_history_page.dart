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
      final data = await DiaryApi.getDiaries(); // ✅ Gọi đúng class
      setState(() {
        diaries = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải nhật ký')),
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
        const SnackBar(content: Text('Chỉ được chỉnh sửa nhật ký trong ngày hôm nay.')),
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
        editingDiary!['date'], // giữ nguyên date cũ
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
        const SnackBar(content: Text('❌ Cập nhật thất bại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📖 Lịch Sử Nhật Ký'),
      ),
      body: diaries.isEmpty
          ? const Center(child: Text('Chưa có nhật ký nào.'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: diaries.length,
        itemBuilder: (context, index) {
          final diary = diaries[index];

          // Lấy date an toàn
          final dateStr = diary['date']?.toString() ?? '';
          DateTime diaryDate;
          try {
            diaryDate = DateTime.parse(dateStr);
          } catch (_) {
            diaryDate = DateTime.now();
          }

          // Lấy content an toàn
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
      // Nút lưu nhanh khi đang chỉnh sửa
      floatingActionButton: editingDiary != null
          ? FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.save),
        onPressed: handleSave,
      )
          : null,
      // Form chỉnh sửa
      bottomSheet: editingDiary != null
          ? Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '📝 Chỉnh sửa nhật ký',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Nhập nội dung mới...',
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
              child: const Text('Lưu thay đổi'),
            ),
          ],
        ),
      )
          : null,
    );
  }
}
