import 'package:flutter/material.dart';
import 'package:trackmentalhealth/core/constants/chat_api.dart';
import 'dart:developer';
import 'package:trackmentalhealth/pages/chat/ChatAI.dart';
import 'package:trackmentalhealth/pages/chat/utils/current_user_id.dart';

import '../../models/ChatMessage.dart';
import '../../models/ChatMessageGroup.dart';
import 'ChatDetail.dart';
import 'ChatDetailGroup.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool loading = false;
  String? error;
  int? currentUserId;

  Map<int, bool> unreadStatus = {}; // sessionId -> true/false
  Map<int, ChatMessage?> lastestMessages =
      {}; // key: sessionId, value: ChatMessage
  Map<int, ChatMessageGroup?> latestMessages = {};
  List<dynamic> sessions = [];
  List<dynamic> myGroup = [];
  List<dynamic> group = [];
  List<dynamic> psychologists = [];

  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
    _initUserIdAndFetchData();
  }

  //get lastest msg by session id
  Future<void> _fetchLastestMessages() async {
    for (var session in sessions) {
      final sessionId = session['id'];
      try {
        final msg = await getLastestMsg(sessionId);
        setState(() {
          lastestMessages[sessionId] = msg; // lưu message cuối
        });
      } catch (e) {
        setState(() {
          lastestMessages[sessionId] = null; // nếu lỗi hoặc chưa có message
        });
      }
    }
  }

  Future<void> loadGroups() async {
    Future<void> loadGroups() async {
      // fetch latest message cho từng group
      for (var grp in group) {
        final latestMsg = await getLastestMsgGroup(grp['id']);
        setState(() {
          latestMessages[grp['id']] = latestMsg;
        });
      }
    }
  }

  Future<void> _initUserIdAndFetchData() async {
    try {
      final id = await getCurrentUserId();
      if (id == null) {
        setState(() => error = "User not logged in. Please login again.");
        return;
      }
      setState(() => currentUserId = id);
      _fetchData();
    } catch (e) {
      setState(() => error = "Error loading user ID: $e");
    }
  }

  Future<void> _fetchData() async {
    if (currentUserId == null) return;

    try {
      setState(() => loading = true);

      final sessionRes = await getChatSessionsByUserId(currentUserId!);
      final myGroupRes = await getChatGroupByCreatorId(currentUserId!);
      final groupRes = await getAllChatGroup();
      final psyRes = await getPsychologists();

      setState(() {
        sessions = sessionRes;
        myGroup = myGroupRes;
        group = groupRes;
        psychologists = psyRes;
        user = {"id": currentUserId, "role": "USER"};
        loading = false;
      });

      _checkUnreadForSessions();
      _fetchLastestMessages();
      loadGroups();

    } catch (e) {
      log("Error load data: $e");
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  Future<void> _checkUnreadForSessions() async {
    for (var session in sessions) {
      final sessionId = session['id'];
      try {
        final hasUnread = await hasUnreadMessages(sessionId);
        setState(() {
          unreadStatus[sessionId] = hasUnread;
        });
      } catch (e) {
        setState(() {
          unreadStatus[sessionId] = false;
        });
      }
    }
  }

  void navigateToAppointment() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Navigate to Appointments")));
  }

  void chatWithPsychologist(int userId) async {
    try {
      final res = await initiateChatSession(currentUserId!, userId);
      log("Initiate chat session: $res");
      // TODO: navigate vào chat detail
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void handleClickSession(Map<String, dynamic> session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetail(
          sessionId: session['id'], // Truyền sessionId vào ChatDetail
        ),
      ),
    );
  }

  void handleOpenCreateGroup() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Open create group modal")));
  }

  void handleEditGroup(Map<String, dynamic> grp) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Edit group ${grp['id']}")));
  }

  void handleDeleteGroup(int groupId) async {
    try {
      await deleteGroupById(groupId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Group deleted successfully")),
      );
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null && error == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(body: Center(child: Text('Error: $error')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messenger', style: TextStyle(color: Colors.teal)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (user != null)
                  OutlinedButton(
                    onPressed: navigateToAppointment,
                    child: const Text('My Appointments'),
                  ),
                if (user != null)
                  DropdownButton<dynamic>(
                    hint: const Text('Chat with Psychologist'),
                    items: psychologists.map((psy) {
                      return DropdownMenuItem(
                        value: psy,
                        child: Text(psy['fullName'] ?? 'No name'),
                      );
                    }).toList(),
                    onChanged: (psy) {
                      if (psy != null)
                        chatWithPsychologist(psy['usersID']['id']);
                    },
                  ),
                if (user?['role'] == 'PSYCHO')
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                    child: const Text('Manage Appointments'),
                  ),
              ],
            ),
          ),
        ),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chat 1-1
                    if (sessions.isEmpty)
                      const Center(
                        child: Text(
                          'No chat session yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      Column(
                        children: sessions.map((session) {
                          final isCurrentUserSender =
                              session['sender']['id'] == currentUserId;
                          final otherUser = isCurrentUserSender
                              ? session['receiver']
                              : session['sender'];

                          final lastMsg = lastestMessages[session['id']];

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      otherUser['avatar'] ??
                                          'https://via.placeholder.com/40',
                                    ),
                                    radius: 20,
                                  ),
                                  if (unreadStatus[session['id']] == true)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    otherUser['fullname']?.toUpperCase() ??
                                        'NO NAME',
                                  ),
                                  if (lastMsg != null)
                                    Text(
                                      TimeOfDay.fromDateTime(
                                        lastMsg.timestamp,
                                      ).format(context),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                lastMsg?.message ?? 'No messages yet',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              onTap: () => handleClickSession(
                                session.cast<String, dynamic>(),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    const Divider(),

                    // My Group
                    if (myGroup.isEmpty)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "You don't have any groups yet.",
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: handleOpenCreateGroup,
                              child: const Text('Create a group chat'),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My Group (${myGroup.length})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              OutlinedButton(
                                onPressed: handleOpenCreateGroup,
                                child: const Text('Add new group ?'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...myGroup.map((grp) {
                            return Card(
                              child: ListTile(
                                onTap: () {
                                  // TODO: navigate to group chat
                                },
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    grp['avt'] ??
                                        'https://via.placeholder.com/40',
                                  ),
                                ),
                                title: Text(grp['name'] ?? 'No name'),
                                subtitle: Text(
                                  grp['des'] ?? 'No description',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () => handleEditGroup(
                                        grp.cast<String, dynamic>(),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          handleDeleteGroup(grp['id']),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),

                    const Divider(),
                    // Other Groups
                    if (group.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chat Group (${group.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...group.map((grp) {
                            final latest = latestMessages[grp['id']];
                            return Card(
                              child: ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatDetailGroup(
                                        groupId: grp['id'] ?? '',
                                        groupName: grp['name'],
                                      ),
                                    ),
                                  );
                                },
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    grp['avt'] ?? 'https://via.placeholder.com/40',
                                  ),
                                ),
                                title: Text(grp['name'] ?? 'No name'),

                                // Nếu có latest message hiển thị tên người gửi + content
                                // nếu chưa có thì hiển thị mô tả group
                                subtitle: Text(
                                  latest != null
                                      ? "${latest.senderName}: ${latest.content}"
                                      : '',
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                trailing: Text(
                                  'Creator: ${grp['createdBy']?['fullname'] ?? 'No data'}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            );
                          }).toList(),

                        ],
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatAI()),
          );
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.mark_chat_unread_outlined),
      ),
    );
  }
}
