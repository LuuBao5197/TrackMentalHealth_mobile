import 'dart:convert'; // Thêm để dùng jsonEncode
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:trackmentalhealth/core/constants/chat_api.dart';
import 'package:trackmentalhealth/pages/chat/utils/StompService.dart';
import 'package:trackmentalhealth/pages/chat/utils/current_user_id.dart';

import '../../models/ChatMessage.dart';
import 'DTO/ChatMessageDTO.dart';

class ChatDetail extends StatefulWidget {
  final int sessionId;

  const ChatDetail({super.key, required this.sessionId});

  @override
  State<ChatDetail> createState() => _ChatDetailState();
}

class _ChatDetailState extends State<ChatDetail> {
  bool loading = true;
  String? error;
  List<types.TextMessage> messages = [];
  String? currentUserId;
  String? receiverName; // tên người nhận
  String? receiverId;
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
        });
        return;
      }
      setState(() => currentUserId = id.toString());

      // Lấy tin nhắn cũ
      final data = await getMessagesBySessionId(widget.sessionId);
      print("📥 Đã tải ${data.length} tin nhắn cũ cho session ${widget.sessionId}");

      final parsedMessages = data.map<types.TextMessage>((json) {
        return ChatMessage.fromJson(json).toTextMessage(currentUserId!);
      }).toList();

      // Xác định tên & ID người nhận
      String? otherName;
      String? otherId;
      for (var msg in data) {
        final senderId = msg['sender']['id'].toString();
        final receiverIdMsg = msg['receiver']['id'].toString();

        if (senderId != currentUserId) {
          otherName = msg['sender']['name'];
          otherId = senderId;
          break;
        } else if (receiverIdMsg != currentUserId) {
          otherName = msg['receiver']['name'];
          otherId = receiverIdMsg;
          break;
        }
      }

      setState(() {
        messages = parsedMessages.reversed.toList();
        receiverName = otherName ?? "Chat";
        receiverId = otherId;
        loading = false;
      });

      // Kết nối STOMP
      stompService = StompService();
      stompService.connect(
        onConnect: (_) {
          stompService.subscribe("/topic/chat/${widget.sessionId}", (frame) {
            if (frame.body != null) {
              print("📩 Nhận tin nhắn mới từ socket: ${frame.body}");

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

                // Cập nhật tên & ID người nhận nếu chưa có
                if (dto.senderId.toString() != currentUserId &&
                    (receiverName == null || receiverName == "Chat")) {
                  receiverName = dto.senderName;
                  receiverId = dto.senderId.toString();
                }
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
    if (currentUserId == null || receiverId == null) {
      print("⚠️ Không thể gửi tin nhắn: currentUserId hoặc receiverId null");
      return;
    }

    // Payload chuẩn JSON
    final payload = {
      "message": message.text,
      "sender": {"id": int.parse(currentUserId!)},
      "receiver": {"id": int.parse(receiverId!)},
      "session": {"id": widget.sessionId},
    };

    print("➡️ Gửi payload: ${jsonEncode(payload)}");

    // Encode JSON trước khi gửi
    stompService.sendMessage("/app/chat/${widget.sessionId}",payload);

    print("✅ Đã gửi tin nhắn qua socket");
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
          receiverName ?? "Chat",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Chat(
          messages: messages,
          onSendPressed: _handleSendPressed,
          user: types.User(id: currentUserId ?? '0'),
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
