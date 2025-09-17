import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:trackmentalhealth/core/constants/chat_api.dart';
import 'package:trackmentalhealth/models/User.dart';
import 'package:trackmentalhealth/utils/StompService.dart';
import 'package:trackmentalhealth/widgets/ConnectionStatusWidget.dart';
import '../../helper/UserSession.dart';
import '../../models/ChatMessage.dart';
import '../../utils/CallInitiator.dart';
import 'DTO/ChatMessageDTO.dart';
import 'VideoCallPage/PrivateCallPage.dart';
import 'VideoCallPage/AgoraVideoCallPage.dart';
import '../../utils/CallSignalListener.dart';

class ChatDetail extends StatefulWidget {
  final int sessionId;
  final User user; // Người nhận

  const ChatDetail({super.key, required this.user, required this.sessionId});

  @override
  State<ChatDetail> createState() => _ChatDetailState();
}

class _ChatDetailState extends State<ChatDetail> {
  bool loading = true;
  String? error;
  List<types.TextMessage> messages = [];
  String? currentUserId;
  String? currentUserAvatar;
  String? currentUserFullName;
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

      currentUserId = id.toString();
      currentUserAvatar = await UserSession.getAvatar();
      currentUserFullName = await UserSession.getFullname();
      setState(() {});

      // Load tin nhắn từ API
      final data = await getMessagesBySessionId(widget.sessionId);
      final parsedMessages = data.map<types.TextMessage>((json) {
        final chatMsg = ChatMessage.fromJson(json);
        final isCurrentUser = chatMsg.senderId.toString() == currentUserId;

        return types.TextMessage(
          id: chatMsg.id.toString(),
          text: chatMsg.message,
          author: types.User(
            id: chatMsg.senderId.toString(),
            firstName: isCurrentUser ? currentUserFullName : widget.user.fullName,
            imageUrl: isCurrentUser ? currentUserAvatar : widget.user.avatar,
          ),
        );
      }).toList();

      setState(() {
        messages = parsedMessages.reversed.toList();
        loading = false;
      });

      // Kết nối Stomp realtime
      stompService = StompService();
      stompService.connect(
        onConnect: (_) {
          stompService.subscribe("/topic/chat/${widget.sessionId}", (frame) {
            // frame đã là Map<String, dynamic>
            final dto = ChatMessageDTO.fromMap(frame); // <-- dùng fromMap thay vì fromRawJson

            final isCurrentUser = dto.senderId.toString() == currentUserId;

            final textMsg = types.TextMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              text: dto.message,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              author: types.User(
                id: dto.senderId.toString(),
                firstName: dto.senderName,
                imageUrl: isCurrentUser ? currentUserAvatar : widget.user.avatar,
              ),
            );
            setState(() {
              messages.insert(0, textMsg);
            });
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
    if (currentUserId == null || widget.user.id == null) return;

    final payload = {
      "message": message.text,
      "sender": {"id": int.parse(currentUserId!)},
      "receiver": {"id": widget.user.id},
      "session": {"id": widget.sessionId},
    };

    stompService.sendMessage("/app/chat/${widget.sessionId}", payload);
  }

  void _startVideoCall() async {
    if (currentUserId == null || widget.user.id == null) return;

    // Kiểm tra kết nối trước khi gọi
    if (!stompService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể gọi video: Mất kết nối mạng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Gửi call request để thông báo cho người nhận (không hiển thị dialog chờ)
      await CallInitiator.sendCallRequest(
        sessionId: widget.sessionId.toString(),
        callerId: currentUserId!,
        callerName: currentUserFullName ?? "User",
        calleeId: widget.user.id.toString(),
        calleeName: widget.user.fullName ?? "User",
        stompService: stompService,
      );
      
      // Người gọi vào thẳng Agora UI (không chờ phản hồi)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AgoraVideoCallPage(
            channelName: widget.sessionId.toString(),
            uid: int.parse(currentUserId!),
            callerName: currentUserFullName ?? "User",
            calleeName: widget.user.fullName ?? "User",
            isCaller: true,
            stompService: stompService,
          ),
        ),
      );
    } catch (e) {
      print("❌ Error starting video call: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting video call: $e')),
      );
    }
  }
  
  void _showConnectionDialog() {
    showDialog(
      context: context,
      builder: (context) => ConnectionStatusDialog(
        stompService: stompService,
      ),
    );
  }

  @override
  void dispose() {
    stompService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (error != null) return Scaffold(body: Center(child: Text("Error: $error")));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(widget.user.fullName ?? 'Chat', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Trạng thái kết nối
          ConnectionStatusWidget(
            stompService: stompService,
            showInAppBar: true,
          ),
          SizedBox(width: 8),
          // Nút video call
          IconButton(
            icon: Icon(Icons.videocam_outlined, size: 35, color: Theme.of(context).colorScheme.onPrimary),
            onPressed: () => _startVideoCall(),
          ),
          // Nút thông tin kết nối
          IconButton(
            icon: Icon(Icons.network_check, color: Theme.of(context).colorScheme.onPrimary),
            onPressed: () => _showConnectionDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Chat(
              messages: messages,
              onSendPressed: _handleSendPressed,
              user: types.User(
                id: currentUserId.toString(),
                firstName: currentUserFullName,
                imageUrl: currentUserAvatar,
              ),
              showUserAvatars: true,
              showUserNames: true,
              theme: DefaultChatTheme(
                primaryColor: Colors.teal.shade600,
                sentMessageBodyTextStyle: const TextStyle(color: Colors.white),
                secondaryColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
                receivedMessageBodyTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                inputBackgroundColor: Theme.of(context).colorScheme.surface,
                inputTextColor: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            // Lắng nghe call signals cho người nhận
            if (currentUserId != null)
              CallSignalListener(
                sessionId: widget.sessionId.toString(),
                currentUserId: currentUserId!,
                currentUserName: currentUserFullName ?? "User",
                stompService: stompService,
              ),
          ],
        ),
      ),
    );
  }
}

