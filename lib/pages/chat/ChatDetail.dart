import 'dart:convert'; // Thêm để dùng jsonEncode
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart' hide ChatMessage;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:trackmentalhealth/core/constants/chat_api.dart';
import 'package:trackmentalhealth/pages/chat/utils/StompService.dart';
import 'package:trackmentalhealth/pages/chat/utils/current_user_id.dart';

import '../../models/ChatMessage.dart';
import 'DTO/ChatMessageDTO.dart';

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
      final id = await getCurrentUserId();
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
      appBar: AppBar(
        title: Text(
          widget.user['fullname'] ?? 'Chat',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined,size: 35, color: Colors.white),
            onPressed: () {
              // Navigator.push(
              //   context,
              //     MaterialPageRoute(
              //       builder: (_) => VideoCall(
              //         sessionId: widget.sessionId.toString(),
              //         currentUserId: currentUserId!,
              //         receiverId: widget.user['id'].toString(),
              //         receiverName: widget.user['fullname'],
              //       ),
              //     ),
              // );
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
            imageUrl: widget.user['avatar'] ?? "", // avatar từ user object
          ),
          showUserAvatars: true,
          showUserNames: true,
          theme: const DefaultChatTheme(
            primaryColor: Colors.teal,
            inputBackgroundColor: Colors.white,
            inputTextColor: Colors.black,
            sentMessageBodyTextStyle: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
