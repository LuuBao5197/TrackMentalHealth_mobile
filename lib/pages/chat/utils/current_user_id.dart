import 'package:shared_preferences/shared_preferences.dart';

Future<int> getCurrentUserId() async {
  final prefs = await SharedPreferences.getInstance();

  // Lấy userId từ SharedPreferences
  final userId = prefs.getInt('userId');

  // Nếu chưa có userId trong bộ nhớ → gán tạm 1 (hoặc 0 nếu muốn check chưa login)
  if (userId == null || userId == 0) {
    print("⚠️ Chưa lưu userId, trả về 1 tạm thời để test");
    return 1;
  }

  print("✅ Lấy userId từ SharedPreferences: $userId");
  return userId;
}
