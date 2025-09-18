import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../core/constants/api_constants.dart' as api_constants;

class StompService {
  late StompClient _stompClient;
  bool _connected = false;
  bool _isConnecting = false;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  final ip = api_constants.ApiConstants.ipLocal;
  late final String _socketUrl = 'ws://$ip:9999/ws';
  
  // Callbacks
  void Function(StompFrame frame)? _onConnectCallback;
  void Function(dynamic error)? _onErrorCallback;
  final Map<String, void Function(dynamic)> _subscriptions = {};

  /// Khởi tạo kết nối STOMP
  void connect({
    required void Function(StompFrame frame) onConnect,
    void Function(dynamic error)? onError,
  }) {
    _onConnectCallback = onConnect;
    _onErrorCallback = onError;
    
    _connectInternal();
  }
  
  /// Kết nối nội bộ với retry logic
  void _connectInternal() {
    if (_isConnecting || _connected) return;
    
    _isConnecting = true;
    _reconnectAttempts++;
    
    print('🔄 [StompService] Kết nối lần $_reconnectAttempts/$_maxReconnectAttempts...');
    
    _stompClient = StompClient(
      config: StompConfig(
        url: _socketUrl,
        onConnect: (frame) {
          _connected = true;
          _isConnecting = false;
          _reconnectAttempts = 0;
          _reconnectTimer?.cancel();
          
          print("✅ [StompService] Đã kết nối thành công");
          
          // Khởi động heartbeat
          _startHeartbeat();
          
          // Resubscribe tất cả subscriptions
          _resubscribeAll();
          
          // Gọi callback
          if (_onConnectCallback != null) {
            _onConnectCallback!(frame);
          }
        },
        beforeConnect: () async {
          print('🔄 [StompService] Đang kết nối...');
          await Future.delayed(const Duration(milliseconds: 500));
        },
        onStompError: (frame) {
          print('❌ [StompService] STOMP error: ${frame.body}');
          _handleConnectionError();
        },
        onWebSocketError: (dynamic error) {
          print('❌ [StompService] WebSocket error: $error');
          _handleConnectionError();
          if (_onErrorCallback != null) {
            _onErrorCallback!(error);
          }
        },
        onDisconnect: (_) {
          _connected = false;
          _isConnecting = false;
          _heartbeatTimer?.cancel();
          print('🔌 [StompService] Đã ngắt kết nối');
          
          // Tự động kết nối lại nếu chưa đạt max attempts
          if (_reconnectAttempts < _maxReconnectAttempts) {
            _scheduleReconnect();
          }
        },
        // Cấu hình heartbeat
        heartbeatIncoming: const Duration(seconds: 30),
        heartbeatOutgoing: const Duration(seconds: 30),
      ),
    );

    _stompClient.activate();
  }
  
  /// Xử lý lỗi kết nối
  void _handleConnectionError() {
    _connected = false;
    _isConnecting = false;
    
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    } else {
      print('❌ [StompService] Đã thử kết nối $_maxReconnectAttempts lần, dừng lại');
    }
  }
  
  /// Lên lịch kết nối lại
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (!_connected && _reconnectAttempts < _maxReconnectAttempts) {
        _connectInternal();
      }
    });
  }
  
  /// Khởi động heartbeat
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_connected) {
        // Gửi ping để kiểm tra kết nối
        _sendHeartbeat();
      } else {
        timer.cancel();
      }
    });
  }
  
  /// Gửi heartbeat
  void _sendHeartbeat() {
    try {
      _stompClient.send(
        destination: '/app/heartbeat',
        body: jsonEncode({
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'type': 'ping'
        }),
      );
    } catch (e) {
      print('❌ [StompService] Lỗi gửi heartbeat: $e');
    }
  }
  
  /// Resubscribe tất cả subscriptions
  void _resubscribeAll() {
    print('🔄 [StompService] Resubscribe ${_subscriptions.length} subscriptions');
    _subscriptions.forEach((destination, callback) {
      _subscribeInternal(destination, callback);
    });
  }

  /// Subscribe tới một topic (chat hoặc call)
  void subscribe(String destination, void Function(dynamic parsed) callback) {
    // Lưu subscription để resubscribe khi kết nối lại
    _subscriptions[destination] = callback;
    
    if (!_connected) {
      print('⚠️ [StompService] Chưa kết nối, sẽ subscribe khi kết nối thành công');
      return;
    }
    
    _subscribeInternal(destination, callback);
  }
  
  /// Subscribe nội bộ
  void _subscribeInternal(String destination, void Function(dynamic parsed) callback) {
    print('🔔 [StompService] Subscribing to $destination');

    _stompClient.subscribe(
      destination: destination,
      callback: (frame) {
        try {
          dynamic raw;

          // Trường hợp frame có body (StompFrame)
          if (frame is StompFrame) {
            if (frame.body == null || frame.body!.isEmpty) {
              print("⚠️ [StompService] Empty frame body from $destination");
              return;
            }
            print("📩 [StompService] Raw frame body from $destination: ${frame.body}");
            raw = jsonDecode(frame.body!);
          }
          // Trường hợp lib trả thẳng Map hoặc String
          else if (frame is String) {
            print("📩 [StompService] Raw string from $destination: $frame");
            raw = jsonDecode(frame as String);
          } else if (frame is Map<String, dynamic>) {
            print("📩 [StompService] Raw map from $destination: $frame");
            raw = frame;
          } else {
            print("⚠️ [StompService] Unexpected frame type: ${frame.runtimeType}");
            return;
          }

          // Trả về cho callback
          if (raw is Map<String, dynamic>) {
            callback(raw);
          } else {
            print("❌ [StompService] Unexpected parsed type: ${raw.runtimeType}");
          }
        } catch (e, s) {
          print("❌ [StompService] Error parsing JSON from $destination: $e");
          print(s);
        }
      },
    );
  }

  /// Gửi tin nhắn chat
  void sendMessage(String destination, Map<String, dynamic> body) {
    _send(destination, body);
  }

  /// Gửi tín hiệu video call (offer, answer, candidate)
  void sendCallSignal(int sessionId, Map<String, dynamic> signal) {
    final destination = "/app/call/$sessionId";
    print("📞 [StompService] Gửi call signal đến $destination: $signal");
    _send(destination, signal);
  }

  /// Hàm private gửi dữ liệu chung
  void _send(String destination, Map<String, dynamic> body) {
    if (!_connected) {
      print('⚠️ [StompService] Không thể gửi, chưa kết nối STOMP');
      // Thử kết nối lại nếu chưa đạt max attempts
      if (_reconnectAttempts < _maxReconnectAttempts) {
        _connectInternal();
      }
      return;
    }

    final jsonBody = jsonEncode(body);
    print('📤 [StompService] Gửi đến $destination: $jsonBody');

    try {
      _stompClient.send(
        destination: destination,
        body: jsonBody,
      );
    } catch (e) {
      print('❌ [StompService] Lỗi gửi dữ liệu: $e');
      _handleConnectionError();
    }
  }

  /// Ngắt kết nối
  void disconnect() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    
    if (_connected) {
      _stompClient.deactivate();
      _connected = false;
      print('🔌 [StompService] Ngắt kết nối thủ công');
    }
    
    _isConnecting = false;
    _reconnectAttempts = 0;
  }
  
  /// Kiểm tra trạng thái kết nối
  bool get isConnected => _connected;
  
  /// Kiểm tra đang kết nối
  bool get isConnecting => _isConnecting;
  
  /// Lấy số lần thử kết nối lại
  int get reconnectAttempts => _reconnectAttempts;
  
  /// Reset số lần thử kết nối lại
  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }
  
  /// Kết nối lại thủ công
  void reconnect() {
    if (!_connected && !_isConnecting) {
      _reconnectAttempts = 0;
      _connectInternal();
    }
  }
  
  /// Dọn dẹp resources
  void dispose() {
    disconnect();
    _subscriptions.clear();
    _onConnectCallback = null;
    _onErrorCallback = null;
  }
}
