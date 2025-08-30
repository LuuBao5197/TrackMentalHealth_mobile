import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../helper/UserSession.dart';
import '../../models/Psychologist.dart';
import '../../models/ChatMessage.dart';
import '../../models/ChatMessageGroup.dart';
import '../../utils/showToast.dart';
import '../appointment/AppointmentForUser/AppointmentPage.dart';
import 'ChatDetail.dart';
import 'ChatDetailGroup.dart';
import 'ChatAI.dart';
import '../../core/constants/chat_api.dart';
import 'VideoCallPage/PublicCallPage.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  int? currentUserId;
  List<dynamic> sessions = [];
  List<dynamic> myGroup = [];
  List<dynamic> group = [];
  List<Psychologist> psychologists = [];
  Map<int, bool> unreadStatus = {};
  Map<int, ChatMessage?> lastestMessages = {};
  Map<int, ChatMessageGroup?> latestMessagesGroup = {};
  bool loading = false;
  String? error;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initUserIdAndFetchData();
  }

  Future<void> _initUserIdAndFetchData() async {
    try {
      final id = await UserSession.getUserId();
      if (id == null) {
        setState(() => error = "User not logged in");
        return;
      }
      setState(() => currentUserId = id);
      _fetchData();
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  Future<void> _fetchData() async {
    if (currentUserId == null) return;
    setState(() => loading = true);
    try {
      final sessionRes = await getChatSessionsByUserId(currentUserId!);
      final myGroupRes = await getChatGroupByCreatorId(currentUserId!);
      final groupRes = await getAllChatGroup();
      final psyRes = await getPsychologists();

      setState(() {
        sessions = sessionRes;
        myGroup = myGroupRes;
        group = groupRes;
        psychologists = psyRes;
        loading = false;
      });

      _fetchLastestMessages();
      _loadGroups();
      _checkUnreadForSessions();
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _fetchLastestMessages() async {
    for (var session in sessions) {
      final sessionId = session['id'];
      try {
        final msg = await getLastestMsg(sessionId);
        setState(() => lastestMessages[sessionId] = msg);
      } catch (_) {
        setState(() => lastestMessages[sessionId] = null);
      }
    }
  }

  Future<void> _loadGroups() async {
    for (var grp in group) {
      final msg = await getLastestMsgGroup(grp['id']);
      setState(() => latestMessagesGroup[grp['id']] = msg);
    }
  }

  Future<void> _checkUnreadForSessions() async {
    for (var session in sessions) {
      final sessionId = session['id'];
      try {
        final hasUnread = await hasUnreadMessages(sessionId);
        setState(() => unreadStatus[sessionId] = hasUnread);
      } catch (_) {
        setState(() => unreadStatus[sessionId] = false);
      }
    }
  }

  void handleClick(dynamic session) {
    final isCurrentUserSender = session['sender']['id'] == currentUserId;
    final otherUser = isCurrentUserSender
        ? session['receiver']
        : session['sender'];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetail(sessionId: session['id'], user: otherUser),
      ),
    );
  }

  void chatWithPsychologist(int userId) async {
    try {
      final res = await initiateChatSession(currentUserId!, userId);
      debugPrint("Initiated chat session: $res");
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void handleOpenCreate() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Open create group modal")));
  }

  void handleEditGroup(Map<String, dynamic> grp) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Edit group ${grp['id']}")));
  }

  void handleDeleteGroup(int groupId) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Delete group $groupId")));
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (error != null)
      return Scaffold(body: Center(child: Text('Error: $error')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messenger'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: OutlinedButton(
              onPressed: () async {
                final userId = await UserSession.getUserId();
                if (userId == null) {
                  print("User ID chưa có");
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AppointmentPage(userId: userId),
                  ),
                );
              }
              ,

              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.teal),
                foregroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'My Appointment',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PublicCallPage(paramRoomID:"0000"),
                  ),
                );              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.teal),
                foregroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: const Text('Public Call', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.teal,
          tabs: const [
            Tab(text: 'User'),
            Tab(text: 'Psychologist'),
            Tab(text: 'Groups'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // User Chat
          ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: sessions.length,
            itemBuilder: (_, index) {
              final session = sessions[index];
              final isCurrentUserSender =
                  session['sender']['id'] == currentUserId;
              final otherUser = isCurrentUserSender
                  ? session['receiver']
                  : session['sender'];
              final lastMsg = lastestMessages[session['id']];
              final unread = unreadStatus[session['id']] ?? false;

              return ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(otherUser['avatar'] ?? ''),
                      radius: 24, // điều chỉnh size nếu muốn
                    ),
                    if (unread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  otherUser['fullname'] ?? 'No Name',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17, // có thể điều chỉnh size
                  ),
                ),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        lastMsg?.message ?? '',
                        style: TextStyle(
                          fontWeight: unread
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (lastMsg != null)
                      Text(
                        DateFormat('HH:mm').format(lastMsg.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                onTap: () => handleClick(session),
              );
            },
          ),

          // Psychologist Chat
          ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: psychologists.length,
            itemBuilder: (_, index) {
              final psy = psychologists[index];
              return ListTile(
                title: Text(psy.usersID?.fullName ?? 'No name'),
                trailing: ElevatedButton(
                  onPressed: () => chatWithPsychologist(psy.usersID!.id!),
                  child: const Text("Chat"),
                ),
              );
            },
          ),

          // Groups
          ListView(
            padding: const EdgeInsets.all(8),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "My Groups (${myGroup.length})",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: handleOpenCreate,
                    child: const Text("Create Group"),
                  ),
                ],
              ),
              ...myGroup.map((grp) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(grp['avt'] ?? ''),
                  ),
                  title: Text(grp['name'] ?? 'No name'),
                  subtitle: Text(grp['des'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => handleEditGroup(grp),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        onPressed: () => handleDeleteGroup(grp['id']),
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailGroup(
                        groupId: grp['id'],
                        groupName: grp['name'],
                      ),
                    ),
                  ),
                );
              }).toList(),
              const Divider(),
              Text(
                "All Groups (${group.length})",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              ...group.map((grp) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(grp['avt'] ?? ''),
                  ),
                  title: Text(
                    "${grp['name']} (${grp['createdBy']?['fullname'] ?? ''})",
                  ),
                  subtitle: Text(grp['des'] ?? ''),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailGroup(
                        groupId: grp['id'],
                        groupName: grp['name'],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatAI()),
        ),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.mark_chat_unread_outlined),
      ),
    );
  }
}
