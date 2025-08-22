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
        _showMessage('📝 Ghi nhật ký thành công!');
        Navigator.pushReplacementNamed(context, '/history');
      } else {
        _showMessage('❌ Lỗi: ${res.statusCode}');
      }
    } catch (e) {
      _showMessage('❌ Đã có lỗi: $e');
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
        title: const Text('🧘‍♀️ Ghi Nhật Ký Cảm Xúc'),
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
                      'Viết ra những điều bạn đang nghĩ, đang cảm nhận...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nút Lưu nhật ký
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _handleSave,
                    icon: const Icon(Icons.save),
                    label: Text(_loading ? 'Đang lưu...' : '💾 Lưu Nhật Ký'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Nút Xem lịch sử nhật ký
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/history');
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('📜 Xem Lịch Sử Nhật Ký'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                )

              ],
            ),
          ),
        ),
      ),
    );
  }
}
