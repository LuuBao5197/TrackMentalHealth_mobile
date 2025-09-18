import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trackmentalhealth/helper/UserSession.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/chat_api.dart';
import '../../utils/showToast.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  int? userId;
  String filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetch();
  }

  Future<void> _loadUserIdAndFetch() async {
    int? id = await UserSession.getUserId();
    if (id == null) return;

    setState(() {
      userId = id;
    });

    await fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    if (userId == null) return;
    try {
      final data = await getNotificationsByUserId(userId!);
      setState(() {
        notifications = data.map((e) => Map<String, dynamic>.from(e)).toList();
        isLoading = false;
      });
    } catch (e) {
      showToast("❌ Lỗi khi lấy thông báo: $e", "error");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> markAsRead(Map<String, dynamic> noti) async {
    try {
      await changeStatusNotification(noti['id']);
      setState(() {
        noti['isRead'] = true;
      });
    } catch (e) {
      showToast("❌ Lỗi đánh dấu đã đọc", "error");
    }
  }

  Future<void> deleteNotification(int id) async {
    try {
      final res = await http.delete(Uri.parse('$notificationUrl/delete/$id'));
      if (res.statusCode == 200) {
        setState(() {
          notifications.removeWhere((n) => n['id'] == id);
        });
        showToast("Notification deleted", "success");
      } else {
        showToast("Failed to delete notification: ${res.statusCode}", "error");
      }
    } catch (e) {
      showToast("Delete failed: $e", "error");
    }
  }

  Future<void> showNotificationDetail(Map<String, dynamic> noti) {
    final theme = Theme.of(context);
    return showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔹 Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications_none,
                      color: theme.colorScheme.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    "Notification Details",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 Body
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (noti['datetime'] != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        DateFormat("HH:mm - dd/MM/yyyy")
                            .format(DateTime.parse(noti['datetime'].toString())),
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),

                  Text(
                    noti['title'] ?? 'Untitled Notification',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      noti['message'] ?? '',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 14, right: 14),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    side: BorderSide(color: theme.colorScheme.outline),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  ),
                  child: Text(
                    "Close",
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (userId == null || isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    List<Map<String, dynamic>> filteredNotifications = filter == 'Unread'
        ? notifications.where((n) => n['isRead'] != true).toList()
        : notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                filter = value;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'All', child: Text('All')),
              PopupMenuItem(value: 'Unread', child: Text('Unread')),
            ],
          ),
        ],
      ),
      body: filteredNotifications.isEmpty
          ? const Center(
        child: Text("No notifications", style: TextStyle(fontSize: 16)),
      )
          : RefreshIndicator(
        onRefresh: fetchNotifications, // khi kéo xuống, gọi fetch lại dữ liệu
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filteredNotifications.length,
          itemBuilder: (context, index) {
            final noti = filteredNotifications[index];
            bool isRead = noti['isRead'] == true;

            return Dismissible(
              key: ValueKey(noti['id']),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Xác nhận xóa"),
                    content: const Text(
                        "Bạn có chắc chắn muốn xóa thông báo này không?"),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text("Hủy")),
                      ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text("Xóa")),
                    ],
                  ),
                );
              },
              onDismissed: (_) => deleteNotification(noti['id']),
              background: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete,
                    color: Colors.white, size: 28),
              ),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: isRead
                    ? theme.colorScheme.surfaceVariant
                    : theme.colorScheme.surface,
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Icon(
                    isRead
                        ? Icons.notifications_none
                        : Icons.notifications_active,
                    color: isRead
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.error,
                    size: 32,
                  ),
                  title: Text(
                    noti['title'] ?? '',
                    style: TextStyle(
                      fontWeight:
                      isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    noti['message'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                    TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  trailing: isRead
                      ? null
                      : Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  onTap: () {
                    markAsRead(noti);
                    showNotificationDetail(noti);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
