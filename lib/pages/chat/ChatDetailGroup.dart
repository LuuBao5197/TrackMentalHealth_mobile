import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:trackmentalhealth/core/constants/chat_api.dart';
import 'package:trackmentalhealth/models/ChatGroup.dart';
import 'package:trackmentalhealth/utils/StompService.dart';
import '../../helper/UserSession.dart';
import '../../models/ChatMessageGroup.dart';
import '../../models/User.dart';
import 'ChatDetail.dart'; // model cho tin nhắn group

class ChatDetailGroup extends StatefulWidget {
  final int groupId;
  final String groupName;
  final String createdBy;


  const ChatDetailGroup({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.createdBy,

  });

  @override
  State<ChatDetailGroup> createState() => _ChatDetailGroupState();
}

class _ChatDetailGroupState extends State<ChatDetailGroup> {
  bool loading = true;
  String? error;
  String? currentUserId;
  List<types.TextMessage> messages = [];

  // Thêm biến cho AppBar
  String? creatorName;
  List<User> members = [];

  late StompService stompService;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  /// Load danh sách thành viên và creator
  Future<void> loadGroupUsers() async {
    try {
      // 1. Lấy thông tin group (để lấy creator)
      final groupJson = await getChatGroupById(widget.groupId);

      // 2. Lấy danh sách members
      final membersJson = await findUsersByGroupId(
        widget.groupId,
        int.parse(currentUserId!),
      );

      setState(() {
        // Parse members từ API findUsersByGroupId
        members = membersJson.map<User>((e) => User.fromJson(e)).toList();

        // Lấy tên creator từ API getChatGroupById
        creatorName = groupJson['createdBy'] != null
            ? groupJson['createdBy']['fullname']
            : 'Unknown';
      });
    } catch (e) {
      print('Error loading group detail: $e');
    }
  }


  /// Khởi tạo chat: lấy tin nhắn và kết nối socket
  Future<void> _initChat() async {
    try {
      // Lấy ID user hiện tại
      final id = await UserSession.getUserId();
      if (id == null) {
        setState(() {
          error = "User not logged in";
        });
        return;
      }
      currentUserId = id.toString();

      // Load thành viên và creator song song
      await loadGroupUsers();

      // Lấy tin nhắn cũ từ API group
      final data = await getMessagesByGroupId(widget.groupId);
      print(
        "📥 Load ${data.length} tin nhắn group cũ cho group ${widget.groupId}",
      );

      final parsedMessages = data.map<types.TextMessage>((json) {
        return ChatMessageGroup.fromJson(json).toTextMessage(currentUserId!);
      }).toList();

      setState(() {
        messages = parsedMessages.reversed.toList();
        loading = false;
      });

      // Kết nối STOMP và subscribe group
      stompService = StompService();
      stompService.connect(
        onConnect: (_) {
          // Subscribe group topic
          stompService.subscribe("/topic/group/${widget.groupId}", (data) {
            try {
              if (data == null) {
                print("⚠️ Nhận được null từ group ${widget.groupId}");
                return;
              }

              if (data is! Map<String, dynamic>) {
                print("⚠️ Dữ liệu không phải Map: $data");
                return;
              }

              print("📩 New message from group ${widget.groupId}: $data");

              final msg = ChatMessageGroup.fromJson(data);

              setState(() {
                messages.insert(0, msg.toTextMessage(currentUserId!));
              });
            } catch (e, s) {
              print("❌ Error parsing JSON from /topic/group/${widget.groupId}: $e\n$s");
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

  /// Gửi tin nhắn group
  void _handleSendPressed(types.PartialText message) async {
    if (currentUserId == null) {
      print("⚠️ currentUserId null, không thể gửi tin nhắn group");
      return;
    }

    // Gửi lên server
    final payload = {
      "groupId": widget.groupId,
      "senderId": int.parse(currentUserId!),
      "content": message.text.toString(),
    };

    print("➡️ Gửi tin nhắn group: $payload");
    stompService.sendMessage("/app/chat.group.send", payload);
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
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.groupName,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              "Created by: ${creatorName ?? widget.createdBy}", // ✅ hiển thị creator
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<User>(
            icon: Row(
              children: [
                const Icon(Icons.group, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  members.length.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white),
              ],
            ),
            onSelected: (User selectedUser) async {
              try {
                // 🔑 Lấy id user hiện tại
                final currentUserId = await UserSession.getUserId();
                if (currentUserId == null) {
                  print("⚠️ User chưa đăng nhập");
                  return;
                }

                // 🔑 Gọi API lấy (hoặc tạo) sessionId
                final sessionJson = await initiateChatSession(
                  currentUserId,
                  selectedUser.id!,
                );

                final sessionId = sessionJson['id'];

                // 👉 Điều hướng sang ChatDetail
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetail(
                      user: selectedUser,   // truyền object User
                      sessionId: sessionId, // truyền sessionId từ API
                    ),
                  ),
                );
              } catch (e) {
                print("❌ Lỗi khi mở chat riêng: $e");
              }
            },
            itemBuilder: (BuildContext context) {
              return members.map((user) {
                return PopupMenuItem<User>(
                  value: user,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: (user.avatar?.isNotEmpty ?? false)
                            ? NetworkImage(user.avatar!)
                            : const AssetImage('assets/images/default_avatar.png')
                        as ImageProvider,
                      ),
                      const SizedBox(width: 8),
                      Text(user.fullName ?? "Unknown"),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: SafeArea(
        child:Chat(
          messages: messages,
          onSendPressed: _handleSendPressed,
          user: types.User(id: currentUserId!),
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
