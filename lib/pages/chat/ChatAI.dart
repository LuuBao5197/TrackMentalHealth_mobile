import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:trackmentalhealth/core/constants/chat_api.dart';
import 'package:trackmentalhealth/helper/UserSession.dart';
import 'package:uuid/uuid.dart';

class ChatAI extends StatefulWidget {
  const ChatAI({super.key});

  @override
  State<ChatAI> createState() => _ChatAIState();
}

class _ChatAIState extends State<ChatAI> {
  final List<types.Message> _messages = [];
  late types.User _user;
  late types.User _aiUser;
  final uuid = const Uuid();
  bool _isLoading = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initUser(); // gọi hàm khởi tạo user
  }

  /// Lấy currentUserId từ SharedPreferences
  Future<void> _initUser() async {
    final id = await UserSession.getUserId(); // hàm utils bạn đã có
    if (!mounted) return;

    setState(() {
      _currentUserId = id;
      _user = types.User(id: id.toString(), firstName: "You");
      _aiUser = const types.User(id: 'ai', firstName: 'AI Doctor');

      // Lời chào ban đầu
      _messages.insert(
        0,
        types.TextMessage(
          id: uuid.v4(),
          author: _aiUser,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          text: "Xin chào! Tôi là AI, ngày hôm nay bạn ổn chứ?",
        ),
      );
    });

    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (_currentUserId == null) {
      debugPrint("⚠️ Không có currentUserId, bỏ qua load history");
      return;
    }

    try {
      debugPrint("🔄 Gọi API getAIHistory cho userId=$_currentUserId ...");
      final history = await getAIHistory(_currentUserId!);

      debugPrint("✅ API trả về ${history.length} items: $history");

      final formatted = history.map<types.Message>((h) {
        final isAI = h['role'] == 'ai';

        int createdAt;
        try {
          createdAt = DateTime.parse(h['timestamp']).millisecondsSinceEpoch;
        } catch (e) {
          debugPrint("⚠️ Lỗi parse timestamp '${h['timestamp']}', dùng thời gian hiện tại");
          createdAt = DateTime.now().millisecondsSinceEpoch;
        }

        return types.TextMessage(
          id: uuid.v4(),
          author: isAI ? _aiUser : _user,
          text: h['message'] ?? "(no message)",
          createdAt: createdAt,
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        _messages.insertAll(0, formatted.reversed);
        _isLoading = false;
      });
    } catch (e, stack) {
      debugPrint("❌ Error load history: $e");
      debugPrint("STACK TRACE: $stack");

      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _handleSendPressed(types.PartialText message) async {
    if (_currentUserId == null) return;

    final userMessage = types.TextMessage(
      id: uuid.v4(),
      author: _user,
      text: message.text,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    setState(() {
      _messages.insert(0, userMessage);
    });

    try {
      final payload = {
        "message": message.text,
        "userId": _currentUserId.toString(),
      };
      final aiReply = await chatAI(payload);

      final aiMessage = types.TextMessage(
        id: uuid.v4(),
        author: _aiUser,
        text: aiReply.toString(),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      if (!mounted) return;
      setState(() {
        _messages.insert(0, aiMessage);
      });
    } catch (e) {
      debugPrint("AI error: $e");

      final errorMessage = types.TextMessage(
        id: uuid.v4(),
        author: _aiUser,
        text: "Không thể phản hồi ngay bây giờ.",
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      if (!mounted) return;
      setState(() {
        _messages.insert(0, errorMessage);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "AI Psychologist",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),

      // Hiển thị loading khi đang load lịch sử
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        user: _user,
        showUserAvatars: false,
        showUserNames: true,
        theme: const DefaultChatTheme(
          primaryColor: Colors.teal,               // màu bong bóng của bạn
          inputBackgroundColor: Colors.white,      // màu input box
          inputTextColor: Colors.black,            // màu chữ trong input
          backgroundColor: Color(0xFFF1F8F6),      // ✅ đổi màu nền ở đây
          sentMessageBodyTextStyle: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
