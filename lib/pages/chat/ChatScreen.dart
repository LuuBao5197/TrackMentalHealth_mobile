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
        title: const Text(
          'Messenger',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        // màu theo theme (light/dark)
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.primary,
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: OutlinedButton.icon(
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
              },
              icon: Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.primary),
              label: Text(
                'My Appointment',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                foregroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PublicCallPage(paramRoomID: "0000"),
                  ),
                );
              },
              icon: Icon(Icons.call, size: 16, color: Theme.of(context).colorScheme.primary),
              label: Text(
                'Public Call',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                foregroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          indicatorColor: Theme.of(context).colorScheme.primary,
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
              final isCurrentUserSender = session['sender']['id'] == currentUserId;
              final otherUser =
              isCurrentUserSender ? session['receiver'] : session['sender'];
              final lastMsg = lastestMessages[session['id']];
              final unread = unreadStatus[session['id']] ?? false;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                color: Theme.of(context).cardColor,
                elevation: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => handleClick(session),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Avatar + chấm unread
                        Stack(
                          children: [
                            CircleAvatar(
                              backgroundImage: (otherUser['avatar'] != null &&
                                  otherUser['avatar'].isNotEmpty)
                                  ? NetworkImage(otherUser['avatar'])
                                  : null,
                              radius: 28,
                              child: (otherUser['avatar'] == null ||
                                  otherUser['avatar'].isEmpty)
                                  ? const Icon(Icons.person, size: 28)
                                  : null,
                            ),
                            if (unread)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).scaffoldBackgroundColor,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Nội dung
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tên
                              Text(
                                otherUser['fullname'] ?? 'No Name',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: unread
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),

                              // Tin nhắn cuối
                              Text(
                                lastMsg?.message ?? '',
                                style: TextStyle(
                                  fontWeight:
                                  unread ? FontWeight.w600 : FontWeight.normal,
                                  color: unread
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Thời gian
                        if (lastMsg != null)
                          Text(
                            DateFormat('HH:mm').format(lastMsg.timestamp),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Psychologist Chat
          ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: psychologists.length,
            itemBuilder: (_, index) {
              final psy = psychologists[index];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundImage: NetworkImage(
                      psy.usersID?.avatar ?? "https://via.placeholder.com/150",
                    ),
                  ),
                  title: Text(
                    psy.usersID?.fullName ?? 'No name',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: () => chatWithPsychologist(psy.usersID!.id!),
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Chat",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20), // bo góc tròn
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
              );
            },
          ),

          // Groups
          ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Header My Groups
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "My Groups (${myGroup.length})",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: handleOpenCreate,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Create"),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Danh sách group của tôi
              ...myGroup.map((grp) {
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundImage: NetworkImage(grp['avt'] ?? ''),
                    ),
                    title: Text(
                      grp['name'] ?? 'No name',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      grp['des'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          onPressed: () => handleEditGroup(grp),
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blueAccent,
                          ),
                        ),
                        IconButton(
                          onPressed: () => handleDeleteGroup(grp['id']),
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
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
                  ),
                );
              }).toList(),

              const Divider(height: 32),

              // Header All Groups
              Text(
                "All Groups (${group.length})",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),

              // Danh sách tất cả group
              ...group.map((grp) {
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 1,
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(grp['avt'] ?? ''),
                    ),
                    title: Text(
                      grp['name'] ?? 'No name',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      "${grp['des'] ?? ''} \nBy ${grp['createdBy']?['fullname'] ?? ''}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    isThreeLine: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailGroup(
                          groupId: grp['id'],
                          groupName: grp['name'],
                        ),
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
        child: const Icon(Icons.mark_chat_unread_outlined, color: Colors.white),
      ),
    );
  }
}
