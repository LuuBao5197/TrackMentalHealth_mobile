import 'package:flutter/material.dart';
import 'package:trackmentalhealth/utils/showToast.dart';
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
      showToast("📵 Cuộc gọi bị từ chối", 'error');
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
    showToast("📵 Cuộc gọi đã kết thúc", 'warning');
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
      showToast("📵 Người nhận đang bận", 'warning');
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.video_call, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text("${signal["callerName"]} đang gọi..."),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Bạn có muốn nhận cuộc gọi video không?"),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _acceptCall(signal, currentUserId, currentUserName, sessionId, stompService, context),
                  icon: Icon(Icons.video_call, color: Colors.white),
                  label: Text("Nhận"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _rejectCall(signal, currentUserId, sessionId, stompService, context),
                  icon: Icon(Icons.call_end, color: Colors.white),
                  label: Text("Từ chối"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
