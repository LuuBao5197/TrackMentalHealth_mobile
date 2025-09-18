import 'package:flutter/material.dart';
import 'package:trackmentalhealth/utils/CallSignalManager.dart';
import 'StompService.dart';

class CallSignalListener extends StatefulWidget {
  final String sessionId;
  final String currentUserId;
  final String currentUserName;
  final StompService stompService;

  const CallSignalListener({
    Key? key,
    required this.sessionId,
    required this.currentUserId,
    required this.currentUserName,
    required this.stompService,
  }) : super(key: key);

  @override
  State<CallSignalListener> createState() => _CallSignalListenerState();
}

class _CallSignalListenerState extends State<CallSignalListener> {
  @override
  void initState() {
    super.initState();

    // Sử dụng StompService đã có sẵn thay vì tạo mới
    if (widget.stompService.isConnected) {
      print("📞 [CallSignalListener] StompService đã kết nối, subscribe call signals ngay");
      _subscribeToCallSignals();
    } else {
      print("📞 [CallSignalListener] StompService chưa kết nối, chờ kết nối...");
      widget.stompService.connect(
        onConnect: (frame) {
          print("📞 [CallSignalListener] Đã kết nối, subscribe call signals");
          _subscribeToCallSignals();
        },
        onError: (error) {
          print("❌ [CallSignalListener] Lỗi kết nối: $error");
          // Có thể hiển thị thông báo lỗi cho user
        },
      );
    }
  }

  void _subscribeToCallSignals() {
    // Lắng nghe call signals cho session cụ thể
    widget.stompService.subscribe("/topic/call/${widget.sessionId}", (signal) {
      print("📞 [CallSignalListener] Nhận call signal: $signal");
      _handleCallSignal(signal);
    });
  }

  void _handleCallSignal(Map<String, dynamic> signal) {
    CallSignalManager.handleCallSignal(
      signal: signal,
      currentUserId: widget.currentUserId,
      currentUserName: widget.currentUserName,
      sessionId: widget.sessionId,
      stompService: widget.stompService,
      context: context,
    );
  }


  @override
  void dispose() {
    // Không disconnect StompService vì nó được dùng chung với ChatDetail
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
