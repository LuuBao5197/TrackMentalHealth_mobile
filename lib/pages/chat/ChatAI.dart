import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:trackmentalhealth/core/constants/chat_api.dart';
import 'package:uuid/uuid.dart';

class ChatAI extends StatefulWidget {
  final int currentUserId;

  const ChatAI({super.key, required this.currentUserId});

  @override
  State<ChatAI> createState() => _ChatAIState();
}

class _ChatAIState extends State<ChatAI> {
  final List<types.Message> _messages = [];
  late types.User _user;
  late types.User _aiUser;
  final uuid = const Uuid();
  bool _isLoading = true; // <-- thêm state loading

  @override
  void initState() {
    super.initState();

    _user = types.User(id: widget.currentUserId.toString(), firstName: "You");
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

    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await getAIHistory(widget.currentUserId);
      final formatted = history.map<types.Message>((h) {
        final isAI = h['role'] == 'ai';
        return types.TextMessage(
          id: uuid.v4(),
          author: isAI ? _aiUser : _user,
          text: h['message'],
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
      }).toList();

      setState(() {
        _messages.insertAll(0, formatted.reversed);
        _isLoading = false; // <-- tắt loading sau khi load xong
      });
    } catch (e) {
      debugPrint("Error load history: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleSendPressed(types.PartialText message) async {
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
        "userId": widget.currentUserId.toString(),
      };
      final aiReply = await chatAI(payload);

      final aiMessage = types.TextMessage(
        id: uuid.v4(),
        author: _aiUser,
        text: aiReply.toString(),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "AI Psychologist",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
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
          primaryColor: Colors.blue,
          inputBackgroundColor: Colors.white,
          inputTextColor: Colors.black,
          sentMessageBodyTextStyle: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
