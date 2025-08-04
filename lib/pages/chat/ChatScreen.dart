import 'package:flutter/material.dart';
import 'package:trackmentalhealth/core/constants/chat_api.dart';
import 'dart:developer';

import 'package:trackmentalhealth/pages/chat/ChatAI.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool loading = false;
  String? error;
  int currentUserId = 1;

  List<dynamic> sessions = []; // chat 1-1
  List<dynamic> myGroup = []; // group của mình
  List<dynamic> group = []; // tất cả group
  List<dynamic> psychologists = []; // dropdown psychologist

  Map<String, dynamic>? user; // user đang login

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      setState(() => loading = true);

      // Gọi song song nhiều API
      final sessionRes = await getChatSessionsByUserId(currentUserId);
      final myGroupRes = await getChatGroupByCreatorId(currentUserId);
      final groupRes = await getAllChatGroup();
      final psyRes = await getPsychologists();

      setState(() {
        sessions = sessionRes;
        myGroup = myGroupRes;
        group = groupRes;
        psychologists = psyRes;
        user = {"id": currentUserId, "role": "USER"}; // giả lập login
        loading = false;
      });
    } catch (e) {
      log("Error load data: $e");
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  void navigateToAppointment() {
    // TODO: navigate đến trang Appointment
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Navigate to Appointments")));
  }

  void chatWithPsychologist(int userId) async {
    try {
      final res = await initiateChatSession(currentUserId, userId);
      log("Initiate chat session: $res");
      // TODO: navigate vào chat detail
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void handleClickSession(Map<String, dynamic> session) {
    // TODO: navigate tới chi tiết chat
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Open chat with session ${session['id']}")),
    );
  }

  void handleOpenCreateGroup() {
    // TODO: mở modal tạo group
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Open create group modal")));
  }

  void handleEditGroup(Map<String, dynamic> grp) {
    // TODO: mở modal edit group
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
      _fetchData(); // refresh
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messenger', style: TextStyle(color: Colors.blue)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Appointments button
          if (user != null)
            OutlinedButton(
              onPressed: navigateToAppointment,
              child: const Text('My Appointments'),
            ),

          // Dropdown psychologist
          if (user != null)
            DropdownButton<dynamic>(
              hint: const Text('Chat with Psychologist'),
              items: psychologists.map((psy) {
                return DropdownMenuItem(
                  value: psy,
                  child: Text(psy['fullname'] ?? 'No name'),
                );
              }).toList(),
              onChanged: (psy) {
                if (psy != null) chatWithPsychologist(psy['usersID']['id']);
              },
            ),

          // Nếu là psychologist → manage appointments
          if (user?['role'] == 'PSYCHO')
            OutlinedButton(
              onPressed: () {
                // TODO: navigate manage appointment
              },
              style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
              child: const Text('Manage Appointments'),
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text('Error: $error'))
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chat 1-1 sessions
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

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(
                                  otherUser['avatar'] ??
                                      'https://via.placeholder.com/40',
                                ),
                                radius: 20,
                              ),
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    otherUser['fullname']?.toUpperCase() ??
                                        'NO NAME',
                                  ),
                                  if (session['timestamp'] != null)
                                    Text(
                                      TimeOfDay.fromDateTime(
                                        DateTime.parse(session['timestamp']),
                                      ).format(context),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      session['latestMessage'] ?? '',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: session['unreadCount'] > 0
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: session['unreadCount'] > 0
                                            ? Colors.black
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  if (session['unreadCount'] > 0)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${session['unreadCount']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
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
                      Column(
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
                                  grp['des'] ?? 'Không có mô tả',
                                  style: const TextStyle(fontSize: 12),
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
            MaterialPageRoute(
              builder: (context) => ChatAI(
                  currentUserId: currentUserId),
            ),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.chat),
      ),
    );
  }
}
