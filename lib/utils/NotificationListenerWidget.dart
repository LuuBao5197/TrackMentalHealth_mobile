import 'package:flutter/material.dart';
import 'StompService.dart';
import 'showToast.dart';

class NotificationListenerWidget extends StatefulWidget {
  final int userId;
  final List<int>? chatSessionIds;
  final List<int>? callSessionIds;

  /// Callback chung khi có sự kiện
  final void Function(Map<String, dynamic> data, String type)? onEvent;

  const NotificationListenerWidget({
    super.key,
    required this.userId,
    this.chatSessionIds,
    this.callSessionIds,
    this.onEvent,
  });

  @override
  State<NotificationListenerWidget> createState() =>
      _NotificationListenerWidgetState();
}

class _NotificationListenerWidgetState
    extends State<NotificationListenerWidget> {
  final StompService _stompService = StompService();

  @override
  void initState() {
    super.initState();

    _stompService.connect(onConnect: (_) {
      // --- Notification ---
      final notifTopic = "/topic/notifications/${widget.userId}";
      _stompService.subscribe(notifTopic, (msg) {
        print("🔔 Notification: $msg");
        showToast("New notification: ${msg['message']}", "info");
        widget.onEvent?.call(msg, "notification");
      });

      // --- Chat ---
      if (widget.chatSessionIds != null) {
        for (var sessionId in widget.chatSessionIds!) {
          final chatTopic = "/topic/chat/$sessionId";
          _stompService.subscribe(chatTopic, (msg) {
            print("💬 Chat message: $msg");
            showToast("New message: ${msg['message']}", "info");
            widget.onEvent?.call(msg, "chat");
          });
        }
      }

      // --- Call ---
      if (widget.callSessionIds != null) {
        for (var sessionId in widget.callSessionIds!) {
          final callTopic = "/topic/call/$sessionId";
          _stompService.subscribe(callTopic, (msg) {
            print("📞 Call signal: $msg");
            showToast("Incoming call...", "info");
            widget.onEvent?.call(msg, "call");
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _stompService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Widget chỉ để lắng nghe, không hiển thị gì
    return const SizedBox.shrink();
  }
}
