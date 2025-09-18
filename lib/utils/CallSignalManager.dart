import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trackmentalhealth/utils/showToast.dart';
import 'package:trackmentalhealth/utils/CallNotificationService.dart';
import 'package:trackmentalhealth/pages/chat/VideoCallPage/AgoraVideoCallPage.dart';
import 'StompService.dart';

class CallSignalManager {
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  
  /// Xử lý tín hiệu video call với validation và retry
  static void handleCallSignal({
    required Map<String, dynamic> signal,
    required String currentUserId,
    required String currentUserName,
    required String sessionId,
    required StompService stompService,
    required BuildContext context,
  }) {
    print("📞 [SignalManager] Nhận tín hiệu: $signal");
    
    // Validate signal
    if (!_validateSignal(signal)) {
      print("❌ [SignalManager] Signal không hợp lệ: $signal");
      return;
    }
    
    final String signalType = signal["type"] as String;
    final String? callerId = signal["callerId"] as String?;
    final String? calleeId = signal["calleeId"] as String?;
    
    switch (signalType) {
      case "CALL_REQUEST":
        _handleCallRequest(signal, currentUserId, currentUserName, sessionId, stompService, context);
        break;
        
      case "CALL_ACCEPTED":
        _handleCallAccepted(signal, currentUserId, currentUserName, sessionId, context);
        break;
        
      case "CALL_REJECTED":
        _handleCallRejected(signal, currentUserId, sessionId, context);
        break;
        
      case "CALL_ENDED":
        _handleCallEnded(signal, currentUserId, sessionId, context);
        break;
        
      case "CALL_BUSY":
        _handleCallBusy(signal, currentUserId, context);
        break;
        
      case "CALL_TIMEOUT":
        _handleCallTimeout(signal, currentUserId, context);
        break;
        
      default:
        print("⚠️ [SignalManager] Loại signal không được hỗ trợ: $signalType");
    }
  }
  
  /// Validate signal có đầy đủ thông tin cần thiết
  static bool _validateSignal(Map<String, dynamic> signal) {
    final requiredFields = ["type"];
    final String signalType = signal["type"] as String? ?? "";
    
    // Kiểm tra các field bắt buộc
    for (String field in requiredFields) {
      if (!signal.containsKey(field) || signal[field] == null) {
        return false;
      }
    }
    
    // Kiểm tra các field cần thiết cho từng loại signal
    switch (signalType) {
      case "CALL_REQUEST":
        return signal.containsKey("callerId") && 
               signal.containsKey("calleeId") &&
               signal.containsKey("callerName");
      case "CALL_ACCEPTED":
      case "CALL_REJECTED":
      case "CALL_ENDED":
        return signal.containsKey("callerId") && 
               signal.containsKey("calleeId");
      default:
        return true;
    }
  }
  
  /// Xử lý yêu cầu gọi video
  static void _handleCallRequest(
    Map<String, dynamic> signal,
    String currentUserId,
    String currentUserName,
    String sessionId,
    StompService stompService,
    BuildContext context,
  ) {
    final String? calleeId = signal["calleeId"] as String?;
    
    if (calleeId == currentUserId) {
      print("📞 [SignalManager] Nhận cuộc gọi từ ${signal["callerName"]}");
      _showIncomingCallDialog(signal, currentUserId, currentUserName, sessionId, stompService, context);
    }
  }
  
  /// Xử lý cuộc gọi được chấp nhận
  static void _handleCallAccepted(
    Map<String, dynamic> signal,
    String currentUserId,
    String currentUserName,
    String sessionId,
    BuildContext context,
  ) {
    final String? callerId = signal["callerId"] as String?;
    
    if (callerId == currentUserId) {
      print("✅ [SignalManager] Cuộc gọi được chấp nhận");
      _navigateToVideoCall(
        context: context,
        channelName: sessionId,
        uid: int.parse(currentUserId),
        callerName: currentUserName,
        calleeName: signal["calleeName"] ?? "Unknown",
        isCaller: true,
        stompService: null, // Có thể cần truyền từ context
      );
    }
  }
  
  /// Xử lý cuộc gọi bị từ chối
  static void _handleCallRejected(
    Map<String, dynamic> signal,
    String currentUserId,
    String sessionId,
    BuildContext context,
  ) {
    final String? callerId = signal["callerId"] as String?;
    
    if (callerId == currentUserId) {
      print("❌ [SignalManager] Cuộc gọi bị từ chối");
      CallNotificationService.showCallRejectedNotification();
      _navigateBackToChat(context, sessionId);
    }
  }
  
  /// Xử lý cuộc gọi kết thúc
  static void _handleCallEnded(
    Map<String, dynamic> signal,
    String currentUserId,
    String sessionId,
    BuildContext context,
  ) {
    print("📵 [SignalManager] Cuộc gọi kết thúc");
    CallNotificationService.showCallEndedNotification();
    _navigateBackToChat(context, sessionId);
  }
  
  /// Xử lý cuộc gọi bận
  static void _handleCallBusy(
    Map<String, dynamic> signal,
    String currentUserId,
    BuildContext context,
  ) {
    final String? callerId = signal["callerId"] as String?;
    
    if (callerId == currentUserId) {
      print("📵 [SignalManager] Người nhận đang bận");
      CallNotificationService.showCallBusyNotification();
    }
  }
  
  /// Xử lý cuộc gọi timeout
  static void _handleCallTimeout(
    Map<String, dynamic> signal,
    String currentUserId,
    BuildContext context,
  ) {
    final String? callerId = signal["callerId"] as String?;
    
    if (callerId == currentUserId) {
      print("⏰ [SignalManager] Cuộc gọi timeout");
      CallNotificationService.stopCallNotification();
      showToast("⏰ Cuộc gọi không được trả lời", 'warning');
    }
  }
  
  /// Hiển thị dialog cuộc gọi đến
  static void _showIncomingCallDialog(
    Map<String, dynamic> signal,
    String currentUserId,
    String currentUserName,
    String sessionId,
    StompService stompService,
    BuildContext context,
  ) {
    // Phát âm thanh cuộc gọi đến
    _playIncomingCallSound();
    
    // Rung thiết bị
    HapticFeedback.heavyImpact();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => IncomingCallDialog(
        signal: signal,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        sessionId: sessionId,
        stompService: stompService,
      ),
    );
  }
  
  /// Phát âm thanh cuộc gọi đến
  static void _playIncomingCallSound() {
    // Sử dụng SystemSound để phát âm thanh cuộc gọi
    SystemSound.play(SystemSoundType.alert);
  }
  
  /// Chấp nhận cuộc gọi
  static void _acceptCall(
    Map<String, dynamic> signal,
    String currentUserId,
    String currentUserName,
    String sessionId,
    StompService stompService,
    BuildContext context,
  ) {
    // Gửi signal chấp nhận
    stompService.sendCallSignal(
      int.parse(sessionId),
      {
        "type": "CALL_ACCEPTED",
        "callerId": signal["callerId"],
        "calleeId": currentUserId,
        "sessionId": sessionId,
        "calleeName": currentUserName,
      },
    );
    
    Navigator.pop(context);
    
    // Chuyển đến trang video call
    Future.delayed(Duration(milliseconds: 100), () {
      if (context.mounted) {
        _navigateToVideoCall(
          context: context,
          channelName: sessionId,
          uid: int.parse(currentUserId),
          callerName: signal["callerName"] ?? "Unknown",
          calleeName: currentUserName,
          isCaller: false,
          stompService: stompService,
        );
      }
    });
  }
  
  /// Từ chối cuộc gọi
  static void _rejectCall(
    Map<String, dynamic> signal,
    String currentUserId,
    String sessionId,
    StompService stompService,
    BuildContext context,
  ) {
    // Gửi signal từ chối
    stompService.sendCallSignal(
      int.parse(sessionId),
      {
        "type": "CALL_REJECTED",
        "callerId": signal["callerId"],
        "calleeId": currentUserId,
        "sessionId": sessionId,
      },
    );
    
    Navigator.pop(context);
  }
  
  /// Chuyển đến trang video call
  static void _navigateToVideoCall({
    required BuildContext context,
    required String channelName,
    required int uid,
    required String callerName,
    required String calleeName,
    required bool isCaller,
    StompService? stompService,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgoraVideoCallPage(
          channelName: channelName,
          uid: uid,
          callerName: callerName,
          calleeName: calleeName,
          isCaller: isCaller,
          stompService: stompService,
        ),
      ),
    );
  }
  
  /// Quay lại trang chat
  static void _navigateBackToChat(BuildContext context, String sessionId) {
    Future.delayed(Duration(milliseconds: 100), () {
      if (context.mounted) {
        Navigator.popUntil(context, ModalRoute.withName("/chat/$sessionId"));
      }
    });
  }
  
  /// Gửi signal với retry mechanism
  static void sendSignalWithRetry({
    required StompService stompService,
    required int sessionId,
    required Map<String, dynamic> signal,
    int retryCount = 0,
  }) {
    try {
      stompService.sendCallSignal(sessionId, signal);
      print("✅ [SignalManager] Gửi signal thành công: ${signal["type"]}");
    } catch (e) {
      if (retryCount < _maxRetries) {
        print("⚠️ [SignalManager] Gửi signal thất bại, retry ${retryCount + 1}/$_maxRetries: $e");
        Future.delayed(_retryDelay, () {
          sendSignalWithRetry(
            stompService: stompService,
            sessionId: sessionId,
            signal: signal,
            retryCount: retryCount + 1,
          );
        });
      } else {
        print("❌ [SignalManager] Gửi signal thất bại sau $_maxRetries lần thử: $e");
      }
    }
  }
}

/// Widget dialog cuộc gọi đến với animation
class IncomingCallDialog extends StatefulWidget {
  final Map<String, dynamic> signal;
  final String currentUserId;
  final String currentUserName;
  final String sessionId;
  final StompService stompService;

  const IncomingCallDialog({
    Key? key,
    required this.signal,
    required this.currentUserId,
    required this.currentUserName,
    required this.sessionId,
    required this.stompService,
  }) : super(key: key);

  @override
  State<IncomingCallDialog> createState() => _IncomingCallDialogState();
}

class _IncomingCallDialogState extends State<IncomingCallDialog>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _soundTimer;

  @override
  void initState() {
    super.initState();
    
    // Animation cho icon cuộc gọi
    _pulseController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Animation cho slide in
    _slideController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    // Bắt đầu animations
    _pulseController.repeat(reverse: true);
    _slideController.forward();
    
    // Phát âm thanh lặp lại
    _startSoundLoop();
  }

  void _startSoundLoop() {
    _soundTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      SystemSound.play(SystemSoundType.alert);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _soundTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade50, Colors.blue.shade100],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar với animation
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.video_call,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
              
              SizedBox(height: 20),
              
              // Tên người gọi
              Text(
                "${widget.signal["callerName"]}",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              
              SizedBox(height: 8),
              
              Text(
                "đang gọi video...",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue.shade600,
                ),
              ),
              
              SizedBox(height: 30),
              
              // Nút bấm
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Nút từ chối
                  _buildCallButton(
                    icon: Icons.call_end,
                    color: Colors.red,
                    onPressed: () => _rejectCall(),
                  ),
                  
                  // Nút nhận
                  _buildCallButton(
                    icon: Icons.video_call,
                    color: Colors.green,
                    onPressed: () => _acceptCall(),
                    isAccept: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isAccept = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  void _acceptCall() {
    _soundTimer?.cancel();
    CallNotificationService.stopCallNotification();
    Navigator.pop(context);
    
    // Gửi signal chấp nhận
    widget.stompService.sendCallSignal(
      int.parse(widget.sessionId),
      {
        "type": "CALL_ACCEPTED",
        "callerId": widget.signal["callerId"],
        "calleeId": widget.currentUserId,
        "sessionId": widget.sessionId,
        "calleeName": widget.currentUserName,
      },
    );
    
    // Chuyển đến trang video call
    Future.delayed(Duration(milliseconds: 100), () {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AgoraVideoCallPage(
              channelName: widget.sessionId,
              uid: int.parse(widget.currentUserId),
              callerName: widget.signal["callerName"] ?? "Unknown",
              calleeName: widget.currentUserName,
              isCaller: false,
              stompService: widget.stompService,
            ),
          ),
        );
      }
    });
  }

  void _rejectCall() {
    _soundTimer?.cancel();
    CallNotificationService.stopCallNotification();
    Navigator.pop(context);
    
    // Gửi signal từ chối
    widget.stompService.sendCallSignal(
      int.parse(widget.sessionId),
      {
        "type": "CALL_REJECTED",
        "callerId": widget.signal["callerId"],
        "calleeId": widget.currentUserId,
        "sessionId": widget.sessionId,
      },
    );
  }
}


