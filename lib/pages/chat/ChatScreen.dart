import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../helper/UserSession.dart';
import '../../models/Psychologist.dart';
import '../../models/ChatMessage.dart';
import '../../models/ChatMessageGroup.dart';
import '../../models/User.dart';
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
  Map<int, double> psyRatings = {};

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

  Future<void> fetchPsyRating(int psyId) async {
    if (psyRatings.containsKey(psyId)) {
      print('Rating for psyId $psyId already fetched: ${psyRatings[psyId]}');
      return; // đã có rating
    }

    try {
      print('Fetching rating for psyId $psyId...');
      final avg = await getAverageRatingByPsychologist(psyId);
      print('Fetched rating for psyId $psyId: $avg');

      setState(() {
        psyRatings[psyId] = avg;
      });
    } catch (e) {
      print('Failed to fetch rating for psyId $psyId: $e');
      psyRatings[psyId] = 0.0;
    }
  }


  Future<void> fetchAllPsyRatings() async {
    for (var psy in psychologists) {
      final psyId = psy.id;
      if (psyId != null) {
        await fetchPsyRating(psyId);
      }
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
      fetchAllPsyRatings();
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
    final otherUserMap  = isCurrentUserSender
        ? session['receiver']
        : session['sender'];

    final otherUser = User.fromJson(otherUserMap);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetail(sessionId: session['id'], user: otherUser),
      ),
    );
  }

  void chatWithPsychologist(int userId) async {
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User ID không hợp lệ")),
      );
      return;
    }

    try {
      final res = await initiateChatSession(currentUserId!, userId);

      if (res != null) {
        debugPrint("Initiated chat session: $res");

        // Convert Map thành User
        final receiver = User.fromJson(res['receiver']);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetail(
              sessionId: res['id'],
              user: receiver, // giờ đây là User object
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không thể tạo phiên chat")),
        );
      }
    } catch (e) {
      debugPrint("Error initiating chat session: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }
  }

  void handleOpenCreate(BuildContext context, Function _fetchData) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController desController = TextEditingController();
    File? selectedImage;

    Future<void> pickImage() async {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        selectedImage = File(image.path);
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tiêu đề
                      Row(
                        children: const [
                          Icon(Icons.group_add, color: Colors.blue, size: 28),
                          SizedBox(width: 8),
                          Text(
                            "Create Group",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Avatar picker
                      InkWell(
                        onTap: () async {
                          await pickImage();
                          setState(() {});
                        },
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.blue[50],
                          backgroundImage: selectedImage != null
                              ? FileImage(selectedImage!)
                              : null,
                          child: selectedImage == null
                              ? const Icon(
                                  Icons.camera_alt,
                                  size: 32,
                                  color: Colors.blueGrey,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Group name
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: "Group Name",
                          prefixIcon: const Icon(Icons.text_fields),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Description
                      TextField(
                        controller: desController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: "Description",
                          prefixIcon: const Icon(Icons.description),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text("Create"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              if (nameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Group name is required"),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              final payload = {
                                "name": nameController.text.trim(),
                                "des": desController.text.trim(),
                                "maxMember": 100,
                                "createdBy": {"id": currentUserId},
                              };
                              try {
                                await createNewGroup(payload, selectedImage);

                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Group '${payload['name']}' created successfully!",
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                _fetchData();
                              } catch (e) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Failed to create group: $e"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void handleEditGroup(
    BuildContext context,
    Map<String, dynamic> grp,
    Function _fetchData,
  )
  {
    final TextEditingController nameController = TextEditingController(
      text: grp['name'] ?? '',
    );
    final TextEditingController desController = TextEditingController(
      text: grp['des'] ?? '',
    );
    File? selectedImage;
    String? currentImage = grp['avt']; // ảnh hiện tại từ backend

    Future<void> pickImage() async {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        selectedImage = File(image.path);
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Row(
                        children: const [
                          Icon(Icons.edit, color: Colors.blue, size: 28),
                          SizedBox(width: 8),
                          Text(
                            "Edit Group",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Avatar
                      InkWell(
                        onTap: () async {
                          await pickImage();
                          setState(() {});
                        },
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.blue[50],
                          backgroundImage: selectedImage != null
                              ? FileImage(selectedImage!)
                              : (currentImage != null
                                        ? NetworkImage(currentImage!)
                                        : null)
                                    as ImageProvider?,
                          child: (selectedImage == null && currentImage == null)
                              ? const Icon(
                                  Icons.camera_alt,
                                  size: 32,
                                  color: Colors.blueGrey,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Group name
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: "Group Name",
                          prefixIcon: const Icon(Icons.text_fields),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Description
                      TextField(
                        controller: desController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: "Description",
                          prefixIcon: const Icon(Icons.description),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text("Save Changes"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              if (nameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Group name is required"),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              final payload = {
                                "id": grp['id'],
                                "name": nameController.text.trim(),
                                "des": desController.text.trim(),
                                "avt": currentImage,
                                "maxMember": grp['maxMember'] ?? 100,
                              };

                              try {
                                await updateGroupById(grp['id'], payload);

                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Group '${payload['name']}' updated successfully!",
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                _fetchData();
                              } catch (e) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Failed to update group: $e"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void handleDeleteGroup(
    BuildContext context,
    int groupId,
    Function _fetchData,
  )
  {
    showDialog(
      context: context,
      barrierDismissible: false, // bắt buộc chọn Cancel/Delete
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
              SizedBox(width: 8),
              Text(
                "Confirm Delete",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            "This action cannot be undone.\nAre you sure you want to delete this group?",
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text("Cancel"),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete, size: 20),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              label: const Text("Delete"),
              onPressed: () async {
                try {
                  await deleteGroupById(groupId);
                  Navigator.pop(ctx);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Group deleted successfully"),
                      backgroundColor: Colors.green,
                    ),
                  );

                  _fetchData(); // reload list
                } catch (e) {
                  Navigator.pop(ctx);
                  print(e);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Failed to delete group: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildStarRating(double rating) {
    final fullStars = rating.floor(); // số sao đầy đủ
    final halfStar = (rating - fullStars) >= 0.5 ? 1 : 0;
    final emptyStars = 5 - fullStars - halfStar;

    return Row(
      children: [
        // Full stars
        for (var i = 0; i < fullStars; i++)
          const Icon(Icons.star, color: Colors.amber, size: 16),
        // Half star
        if (halfStar == 1)
          const Icon(Icons.star_half, color: Colors.amber, size: 16),
        // Empty stars
        for (var i = 0; i < emptyStars; i++)
          const Icon(Icons.star_border, color: Colors.amber, size: 16),
        const SizedBox(width: 4),
        // Số rating
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
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
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).colorScheme.surface,
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
              icon: Icon(
                Icons.calendar_today,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
                    builder: (context) =>
                        const PublicCallPage(paramRoomID: "0000"),
                  ),
                );
              },
              icon: Icon(
                Icons.call,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
              final isCurrentUserSender =
                  session['sender']['id'] == currentUserId;
              final otherUser = isCurrentUserSender
                  ? session['receiver']
                  : session['sender'];
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
                              backgroundImage:
                                  (otherUser['avatar'] != null &&
                                      otherUser['avatar'].isNotEmpty)
                                  ? NetworkImage(otherUser['avatar'])
                                  : null,
                              radius: 28,
                              child:
                                  (otherUser['avatar'] == null ||
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
                                      color: Theme.of(
                                        context,
                                      ).scaffoldBackgroundColor,
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
                                      : Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),

                              // Tin nhắn cuối
                              Text(
                                lastMsg?.message ?? '',
                                style: TextStyle(
                                  fontWeight: unread
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: unread
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color,
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
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
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

              // Lấy rating nếu chưa có
              final rating = psyRatings[psy.id] ?? 0.0;
              print('Rating for psyId ${psy.id} = $rating');

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
                    backgroundImage:
                        (psy.usersID?.avatar != null &&
                            psy.usersID!.avatar!.startsWith("http"))
                        ? NetworkImage(psy.usersID!.avatar!)
                        : const NetworkImage("https://via.placeholder.com/150"),
                  ),

                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        psy.usersID?.fullName ?? 'No name',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      buildStarRating(psyRatings[psy.id] ?? 0.0),
                    ],
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
                    onPressed: () {
                      handleOpenCreate(context, _fetchData);
                    },
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
                          onPressed: () =>
                              handleEditGroup(context, grp, _fetchData),
                          icon: const Icon(Icons.edit_note, color: Colors.teal),
                        ),
                        IconButton(
                          onPressed: () =>
                              handleDeleteGroup(context, grp['id'], _fetchData),
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
                          createdBy: grp['createdBy']?['fullname'] ?? 'Unknown', // ✅ lấy fullname
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
                          createdBy: grp['createdBy']?['fullname'] ?? 'Unknown', // ✅ lấy fullname
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
