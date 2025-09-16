import 'package:flutter/material.dart';
import 'package:trackmentalhealth/utils/CallSignalManager.dart';
import 'package:trackmentalhealth/utils/showToast.dart';
import 'StompService.dart';

class CallInitiator {
  static const Duration _callTimeout = Duration(seconds: 30);
  
  /// Khởi tạo cuộc gọi video
  static Future<void> initiateCall({
    required String sessionId,
    required String callerId,
    required String callerName,
    required String calleeId,
    required String calleeName,
    required StompService stompService,
    required BuildContext context,
  }) async {
    print("📞 [CallInitiator] Bắt đầu cuộc gọi từ $callerName đến $calleeName");
    
    try {
      // Gửi signal yêu cầu gọi
      CallSignalManager.sendSignalWithRetry(
        stompService: stompService,
        sessionId: int.parse(sessionId),
        signal: {
          "type": "CALL_REQUEST",
          "callerId": callerId,
          "calleeId": calleeId,
          "callerName": callerName,
          "calleeName": calleeName,
          "sessionId": sessionId,
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      // Hiển thị dialog đang gọi
      _showCallingDialog(
        context: context,
        calleeName: calleeName,
        onCancel: () => _cancelCall(sessionId, callerId, calleeId, stompService, context),
      );
      
      // Set timeout cho cuộc gọi
      _setCallTimeout(sessionId, callerId, calleeId, stompService, context);
      
    } catch (e) {
      print("❌ [CallInitiator] Lỗi khi khởi tạo cuộc gọi: $e");
      showToast("❌ Không thể khởi tạo cuộc gọi", 'error');
    }
  }
  
  /// Hiển thị dialog đang gọi
  static void _showCallingDialog({
    required BuildContext context,
    required String calleeName,
    required VoidCallback onCancel,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text("Đang gọi $calleeName..."),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Vui lòng chờ người nhận trả lời"),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: onCancel,
                  icon: Icon(Icons.call_end, color: Colors.white),
                  label: Text("Hủy"),
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
  
  /// Hủy cuộc gọi
  static void _cancelCall(
    String sessionId,
    String callerId,
    String calleeId,
    StompService stompService,
    BuildContext context,
  ) {
    print("📵 [CallInitiator] Hủy cuộc gọi");
    
    // Gửi signal hủy cuộc gọi
    CallSignalManager.sendSignalWithRetry(
      stompService: stompService,
      sessionId: int.parse(sessionId),
      signal: {
        "type": "CALL_ENDED",
        "callerId": callerId,
        "calleeId": calleeId,
        "sessionId": sessionId,
        "reason": "CANCELLED",
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      },
    );
    
    Navigator.pop(context);
    showToast("📵 Đã hủy cuộc gọi", 'info');
  }
  
  /// Set timeout cho cuộc gọi
  static void _setCallTimeout(
    String sessionId,
    String callerId,
    String calleeId,
    StompService stompService,
    BuildContext context,
  ) {
    Future.delayed(_callTimeout, () {
      if (context.mounted) {
        // Kiểm tra xem dialog đang gọi còn hiển thị không
        if (Navigator.canPop(context)) {
          print("⏰ [CallInitiator] Cuộc gọi timeout");
          
          // Gửi signal timeout
          CallSignalManager.sendSignalWithRetry(
            stompService: stompService,
            sessionId: int.parse(sessionId),
            signal: {
              "type": "CALL_TIMEOUT",
              "callerId": callerId,
              "calleeId": calleeId,
              "sessionId": sessionId,
              "timestamp": DateTime.now().millisecondsSinceEpoch,
            },
          );
          
          Navigator.pop(context);
          showToast("⏰ Cuộc gọi không được trả lời", 'warning');
        }
      }
    });
  }
  
  /// Kết thúc cuộc gọi
  static void endCall({
    required String sessionId,
    required String callerId,
    required String calleeId,
    required StompService stompService,
    required BuildContext context,
  }) {
    print("📵 [CallInitiator] Kết thúc cuộc gọi");
    
    // Gửi signal kết thúc cuộc gọi
    CallSignalManager.sendSignalWithRetry(
      stompService: stompService,
      sessionId: int.parse(sessionId),
      signal: {
        "type": "CALL_ENDED",
        "callerId": callerId,
        "calleeId": calleeId,
        "sessionId": sessionId,
        "reason": "ENDED",
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      },
    );
    
    Navigator.pop(context);
  }
  
  /// Kiểm tra trạng thái cuộc gọi
  static bool isCallInProgress(BuildContext context) {
    return Navigator.canPop(context);
  }
}
