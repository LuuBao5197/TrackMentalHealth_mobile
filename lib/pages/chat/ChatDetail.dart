import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:trackmentalhealth/core/constants/chat_api.dart';
import 'package:trackmentalhealth/models/User.dart';
import 'package:trackmentalhealth/utils/StompService.dart';
import 'package:trackmentalhealth/widgets/ConnectionStatusWidget.dart';
import '../../core/constants/api_constants.dart';
import '../../helper/UserSession.dart';
import '../../models/ChatMessage.dart';
import '../../utils/CallInitiator.dart';
import '../../utils/CallSignalManager.dart';
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
      print("🔄 [ChatDetail] ====== INITIALIZING WEBSOCKET ======");
      print("🔄 [ChatDetail] Session ID: ${widget.sessionId}");
      print("🔄 [ChatDetail] Current User ID: $currentUserId");
      print("🔄 [ChatDetail] Target User ID: ${widget.user.id}");
      print("🔄 [ChatDetail] WebSocket URL: ws://${ApiConstants.ipLocal}:9999/ws");
      
      stompService.connect(
        onConnect: (_) {
          print("✅ [ChatDetail] ====== ONCONNECT CALLBACK CALLED ======");
          print("✅ [ChatDetail] WebSocket connected for session: ${widget.sessionId}");
          print("✅ [ChatDetail] Connection status: ${stompService.isConnected}");
          print("✅ [ChatDetail] Subscribing to: /topic/chat/${widget.sessionId}");
          
          print("🔔 [ChatDetail] About to call subscribe for chat...");
          stompService.subscribe("/topic/chat/${widget.sessionId}", (frame) {
            print("🔔 [ChatDetail] ====== WEBSOCKET MESSAGE RECEIVED ======");
            print("🔔 [ChatDetail] Raw frame: $frame");
            print("🔔 [ChatDetail] Frame type: ${frame.runtimeType}");
            
            try {
              // Parse dữ liệu từ WebSocket
              final dto = ChatMessageDTO.fromMap(frame);
              print("🔔 [ChatDetail] Parsed DTO: message='${dto.message}', senderId=${dto.senderId}, senderName='${dto.senderName}'");

              final isCurrentUser = dto.senderId.toString() == currentUserId;
              print("🔔 [ChatDetail] Is current user: $isCurrentUser (currentUserId: $currentUserId)");

              // Kiểm tra xem tin nhắn này có phải từ user hiện tại không
              // Nếu có thì có thể đã được hiển thị qua optimistic update
              if (isCurrentUser) {
                // Kiểm tra xem tin nhắn đã tồn tại chưa (tránh duplicate)
                final messageExists = messages.any((msg) => 
                  msg.text == dto.message && 
                  msg.author.id == dto.senderId.toString()
                );
                
                print("🔔 [ChatDetail] Message already exists: $messageExists");
                if (messageExists) {
                  print("🔔 [ChatDetail] Skipping duplicate message");
                  return;
                }
              }

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
              
              print("🔔 [ChatDetail] Adding message to UI: '${dto.message}' from ${dto.senderName}");
              setState(() {
                messages.insert(0, textMsg);
              });
              print("🔔 [ChatDetail] Message added successfully. Total messages: ${messages.length}");
              print("🔔 [ChatDetail] ====== END WEBSOCKET MESSAGE ======");
            } catch (e) {
              print("❌ [ChatDetail] Error parsing message: $e");
              print("❌ [ChatDetail] Raw frame that caused error: $frame");
            }
          });

          // Subscribe call signals cho session này
          print("📞 [ChatDetail] Subscribing to call signals: /topic/call/${widget.sessionId}");
          print("📞 [ChatDetail] Current user ID for call: $currentUserId");
          print("📞 [ChatDetail] Target user ID for call: ${widget.user.id}");
          
          stompService.subscribe("/topic/call/${widget.sessionId}", (signal) {
            print("📞 [ChatDetail] ====== CALL SIGNAL RECEIVED ======");
            print("📞 [ChatDetail] Call signal: $signal");
            print("📞 [ChatDetail] Signal type: ${signal['type']}");
            print("📞 [ChatDetail] Signal callerId: ${signal['callerId']}");
            print("📞 [ChatDetail] Signal calleeId: ${signal['calleeId']}");
            print("📞 [ChatDetail] Signal sessionId: ${signal['sessionId']}");
            print("📞 [ChatDetail] Current user ID: $currentUserId");
            
            // Xử lý call signal thông qua CallSignalManager
            if (currentUserId != null && currentUserFullName != null) {
              print("📞 [ChatDetail] Calling CallSignalManager.handleCallSignal...");
              CallSignalManager.handleCallSignal(
                signal: signal,
                currentUserId: currentUserId!,
                currentUserName: currentUserFullName!,
                sessionId: widget.sessionId.toString(),
                stompService: stompService,
                context: context,
              );
            } else {
              print("❌ [ChatDetail] Cannot handle call signal - missing user info");
            }
          });
        },
        onError: (error) {
          print("❌ [ChatDetail] WebSocket error: $error");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chat connection error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
      
      // Debug: Kiểm tra connection status sau 2 giây
      Future.delayed(Duration(seconds: 2), () {
        print("🔍 [ChatDetail] ====== CONNECTION STATUS CHECK ======");
        print("🔍 [ChatDetail] Connection status after 2s: ${stompService.isConnected}");
        print("🔍 [ChatDetail] Is connecting: ${stompService.isConnecting}");
        print("🔍 [ChatDetail] Reconnect attempts: ${stompService.reconnectAttempts}");
        print("🔍 [ChatDetail] Session ID: ${widget.sessionId}");
        print("🔍 [ChatDetail] Current User ID: $currentUserId");
        print("🔍 [ChatDetail] Target User ID: ${widget.user.id}");
        
        if (!stompService.isConnected) {
          print("❌ [ChatDetail] WebSocket not connected after 2 seconds!");
          print("❌ [ChatDetail] Attempting manual reconnect...");
          stompService.reconnect();
        } else {
          print("✅ [ChatDetail] WebSocket is connected!");
          print("🔔 [ChatDetail] Manually subscribing to chat topic...");
          stompService.subscribe("/topic/chat/${widget.sessionId}", (frame) {
            print("🔔 [ChatDetail] ====== MANUAL SUBSCRIBE MESSAGE RECEIVED ======");
            print("🔔 [ChatDetail] Raw frame: $frame");
            print("🔔 [ChatDetail] Frame type: ${frame.runtimeType}");
            
            try {
              // Parse dữ liệu từ WebSocket
              final dto = ChatMessageDTO.fromMap(frame);
              print("🔔 [ChatDetail] Parsed DTO: message='${dto.message}', senderId=${dto.senderId}, senderName='${dto.senderName}'");

              final isCurrentUser = dto.senderId.toString() == currentUserId;
              print("🔔 [ChatDetail] Is current user: $isCurrentUser (currentUserId: $currentUserId)");

              // Kiểm tra xem tin nhắn này có phải từ user hiện tại không
              if (isCurrentUser) {
                // Kiểm tra xem tin nhắn đã tồn tại chưa (tránh duplicate)
                final messageExists = messages.any((msg) => 
                  msg.text == dto.message && 
                  msg.author.id == dto.senderId.toString()
                );
                
                print("🔔 [ChatDetail] Message already exists: $messageExists");
                if (messageExists) {
                  print("🔔 [ChatDetail] Skipping duplicate message");
                  return;
                }
              }

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
              
              print("🔔 [ChatDetail] Adding message to UI: '${dto.message}' from ${dto.senderName}");
              setState(() {
                messages.insert(0, textMsg);
              });
              print("🔔 [ChatDetail] Message added successfully. Total messages: ${messages.length}");
              print("🔔 [ChatDetail] ====== END MANUAL SUBSCRIBE MESSAGE ======");
            } catch (e) {
              print("❌ [ChatDetail] Error parsing message: $e");
              print("❌ [ChatDetail] Raw frame that caused error: $frame");
            }
          });
        }
      });

      // Test: Gửi test message để kiểm tra connection
      Future.delayed(Duration(seconds: 5), () {
        print("🧪 [ChatDetail] ====== TESTING WEBSOCKET CONNECTION ======");
        print("🧪 [ChatDetail] Sending test call signal...");
        
        // Gửi test call signal
        stompService.sendCallSignal(widget.sessionId, {
          "type": "TEST_CALL_REQUEST",
          "callerId": currentUserId,
          "calleeId": widget.user.id.toString(),
          "sessionId": widget.sessionId.toString(),
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        });
        
        print("🧪 [ChatDetail] Test call signal sent");
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;

      });
    }
  }

  void _handleSendPressed(types.PartialText message) async {
    print("🚀 [ChatDetail] ====== HANDLE SEND PRESSED ======");
    print("🚀 [ChatDetail] Message text: '${message.text}'");
    print("🚀 [ChatDetail] Current user ID: $currentUserId");
    print("🚀 [ChatDetail] Target user ID: ${widget.user.id}");
    print("🚀 [ChatDetail] Session ID: ${widget.sessionId}");
    
    if (currentUserId == null || widget.user.id == null) {
      print("❌ [ChatDetail] Missing user IDs - currentUserId: $currentUserId, targetUserId: ${widget.user.id}");
      return;
    }

    // Kiểm tra tin nhắn không rỗng
    if (message.text.trim().isEmpty) {
      print("⚠️ [ChatDetail] Empty message text");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message cannot be empty'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    print("🔍 [ChatDetail] Checking WebSocket connection...");
    print("🔍 [ChatDetail] isConnected: ${stompService.isConnected}");
    print("🔍 [ChatDetail] isConnecting: ${stompService.isConnecting}");
    print("🔍 [ChatDetail] reconnectAttempts: ${stompService.reconnectAttempts}");
    
    if (!stompService.isConnected) {
      print("❌ [ChatDetail] WebSocket not connected, attempting reconnect...");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection lost, attempting to reconnect...'),
          backgroundColor: Colors.red,
        ),
      );
      // Thử kết nối lại
      stompService.reconnect();
      return;
    }

    try {
      final payload = {
        "message": message.text.trim(),
        "sender": {"id": int.parse(currentUserId!)},
        "receiver": {"id": widget.user.id},
        "session": {"id": widget.sessionId},
      };

      print("📤 [ChatDetail] ====== SENDING MESSAGE ======");
      print("📤 [ChatDetail] Destination: /app/chat/${widget.sessionId}");
      print("📤 [ChatDetail] Payload: $payload");
      print("📤 [ChatDetail] Connection status: ${stompService.isConnected}");
      
      stompService.sendMessage("/app/chat/${widget.sessionId}", payload);
      
      // Hiển thị tin nhắn tạm thời trong UI (optimistic update)
      final tempMessage = types.TextMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: message.text,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        author: types.User(
          id: currentUserId!,
          firstName: currentUserFullName,
          imageUrl: currentUserAvatar,
        ),
      );
      
      print("📤 [ChatDetail] Adding optimistic message to UI: '${message.text}'");
      setState(() {
        messages.insert(0, tempMessage);
      });
      print("📤 [ChatDetail] Optimistic message added. Total messages: ${messages.length}");
      print("📤 [ChatDetail] ====== END SENDING MESSAGE ======");
      
    } catch (e) {
      print("❌ [ChatDetail] Error sending message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startVideoCall() async {
    if (currentUserId == null || widget.user.id == null) return;

    // Kiểm tra kết nối trước khi gọi
    if (!stompService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot make video call: Network connection lost'),
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
            // Lắng nghe call signals cho người nh
            // Lắng nghe call signals cho người nh
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

