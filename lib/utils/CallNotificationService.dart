import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trackmentalhealth/utils/showToast.dart';

class CallNotificationService {
  static Timer? _callTimer;
  static bool _isCallActive = false;
  
  /// Hiển thị thông báo cuộc gọi đến
  static void showIncomingCallNotification({
    required String callerName,
    required VoidCallback onAccept,
    required VoidCallback onReject,
    Duration timeout = const Duration(seconds: 30),
  }) {
    if (_isCallActive) return;
    
    _isCallActive = true;
    
    // Phát âm thanh cuộc gọi
    _playCallSound();
    
    // Rung thiết bị
    HapticFeedback.heavyImpact();
    
    // Hiển thị toast thông báo
    showToast("📞 $callerName đang gọi video...", 'info');
    
    // Set timeout cho cuộc gọi
    _setCallTimeout(timeout);
  }
  
  /// Phát âm thanh cuộc gọi
  static void _playCallSound() {
    // Phát âm thanh hệ thống
    SystemSound.play(SystemSoundType.alert);
    
    // Lặp lại âm thanh mỗi 2 giây
    _callTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (_isCallActive) {
        SystemSound.play(SystemSoundType.alert);
      } else {
        timer.cancel();
      }
    });
  }
  
  /// Set timeout cho cuộc gọi
  static void _setCallTimeout(Duration timeout) {
    Timer(timeout, () {
      if (_isCallActive) {
        _stopCallNotification();
        showToast("⏰ Cuộc gọi không được trả lời", 'warning');
      }
    });
  }
  
  /// Dừng thông báo cuộc gọi
  static void stopCallNotification() {
    _stopCallNotification();
  }
  
  static void _stopCallNotification() {
    _isCallActive = false;
    _callTimer?.cancel();
    _callTimer = null;
  }
  
  /// Kiểm tra xem có cuộc gọi đang hoạt động không
  static bool get isCallActive => _isCallActive;
  
  /// Hiển thị thông báo cuộc gọi kết thúc
  static void showCallEndedNotification() {
    _stopCallNotification();
    
    // Rung nhẹ khi kết thúc cuộc gọi
    HapticFeedback.lightImpact();
    
    showToast("📵 Cuộc gọi đã kết thúc", 'info');
  }
  
  /// Hiển thị thông báo cuộc gọi bị từ chối
  static void showCallRejectedNotification() {
    _stopCallNotification();
    
    showToast("📵 Cuộc gọi bị từ chối", 'warning');
  }
  
  /// Hiển thị thông báo cuộc gọi bận
  static void showCallBusyNotification() {
    _stopCallNotification();
    
    showToast("📵 Người nhận đang bận", 'warning');
  }
  
  /// Hiển thị thông báo lỗi cuộc gọi
  static void showCallErrorNotification(String error) {
    _stopCallNotification();
    
    showToast("❌ Lỗi cuộc gọi: $error", 'error');
  }
  
  /// Dọn dẹp service
  static void dispose() {
    _stopCallNotification();
  }
}
