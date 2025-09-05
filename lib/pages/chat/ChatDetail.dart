import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:trackmentalhealth/core/constants/chat_api.dart';
import 'package:trackmentalhealth/pages/chat/utils/StompService.dart';

import '../../helper/UserSession.dart';
import '../../models/ChatMessage.dart';
import 'DTO/ChatMessageDTO.dart';
import 'VideoCallPage/PrivateCallPage.dart';

class ChatDetail extends StatefulWidget {
  final int sessionId;
  final Map<String, dynamic> user;

  const ChatDetail({super.key, required this.user, required this.sessionId});

  @override
  State<ChatDetail> createState() => _ChatDetailState();
}

class _ChatDetailState extends State<ChatDetail> {
  bool loading = true;
  String? error;
  List<types.TextMessage> messages = [];
  String? currentUserId;
  late StompService stompService;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      final id = await UserSession.getUserId();
      if (id == null) {
        setState(() {
          error = "User not logged in";
          loading = false;
        });
        return;
      }
      setState(() => currentUserId = id.toString());

      final data = await getMessagesBySessionId(widget.sessionId);
      final parsedMessages = data.map<types.TextMessage>((json) {
        return ChatMessage.fromJson(json).toTextMessage(currentUserId!);
      }).toList();

      setState(() {
        messages = parsedMessages.reversed.toList();
        loading = false;
      });

      stompService = StompService();
      stompService.connect(
        onConnect: (_) {
          stompService.subscribe("/topic/chat/${widget.sessionId}", (frame) {
            if (frame.body != null) {
              final dto = ChatMessageDTO.fromRawJson(frame.body!);

              final textMsg = types.TextMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                text: dto.message,
                author: types.User(
                  id: dto.senderId.toString(),
                  firstName: dto.senderName,
                ),
                createdAt: DateTime.now().millisecondsSinceEpoch,
              );

              setState(() {
                messages.insert(0, textMsg);
              });
            }
          });
        },
      );
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void _handleSendPressed(types.PartialText message) async {
    if (currentUserId == null || widget.user['id'] == null) {
      print("⚠️ Không thể gửi tin nhắn: currentUserId hoặc receiverId null");
      return;
    }

    final payload = {
      "message": message.text,
      "sender": {"id": int.parse(currentUserId!)},
      "receiver": {"id": widget.user['id']},
      "session": {"id": widget.sessionId},
    };

    stompService.sendMessage("/app/chat/${widget.sessionId}", payload);
  }

  @override
  void dispose() {
    stompService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return Scaffold(body: Center(child: Text("Error: $error")));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // ✅ nền đổi theo theme
      appBar: AppBar(
        title: Text(
          widget.user['fullname'] ?? 'Chat',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.videocam_outlined, size: 35, color: Theme.of(context).colorScheme.onPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PrivateCallPage(
                    sessionId: widget.sessionId.toString(),
                    currentUserId: currentUserId!,
                    currentUserName: widget.user['fullname'],
                    // isCaller: true,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Chat(
          messages: messages,
          onSendPressed: _handleSendPressed,
          user: types.User(
            id: currentUserId ?? '0',
            imageUrl: widget.user['avatar'] ?? "",
          ),
          showUserAvatars: true,
          showUserNames: true,
          theme: DefaultChatTheme(
            // Bong bóng tin nhắn mình gửi
            primaryColor: Colors.teal.shade600,
            sentMessageBodyTextStyle: const TextStyle(color: Colors.white),

            // Bong bóng tin nhắn nhận
            secondaryColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.grey.shade200,
            receivedMessageBodyTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),

            // Input
            inputBackgroundColor: Theme.of(context).colorScheme.surface,
            inputTextColor: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
