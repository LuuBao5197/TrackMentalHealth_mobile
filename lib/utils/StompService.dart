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
    print("🔄 [StompService] ====== CONNECT CALLED ======");
    print("🔄 [StompService] WebSocket URL: $_socketUrl");
    print("🔄 [StompService] Current connection status: $_connected");
    print("🔄 [StompService] Is connecting: $_isConnecting");
    
    _onConnectCallback = onConnect;
    _onErrorCallback = onError;
    
    _connectInternal();
  }
  
  /// Kết nối nội bộ với retry logic
  void _connectInternal() {
    print("🔄 [StompService] ====== CONNECT INTERNAL ======");
    print("🔄 [StompService] _isConnecting: $_isConnecting");
    print("🔄 [StompService] _connected: $_connected");
    print("🔄 [StompService] _reconnectAttempts: $_reconnectAttempts");
    
    if (_isConnecting || _connected) {
      print("⚠️ [StompService] Already connecting or connected, skipping");
      return;
    }
    
    _isConnecting = true;
    _reconnectAttempts++;
    
    print("🔄 [StompService] Creating StompClient with URL: $_socketUrl");
    _stompClient = StompClient(
      config: StompConfig(
        url: _socketUrl,
        onConnect: (frame) {
          print("✅ [StompService] ====== CONNECTED ======");
          print("✅ [StompService] Connect frame: $frame");
          
          _connected = true;
          _isConnecting = false;
          _reconnectAttempts = 0;
          _reconnectTimer?.cancel();
          
          print("✅ [StompService] Starting heartbeat...");
          // Khởi động heartbeat
          _startHeartbeat();
          
          print("✅ [StompService] Resubscribing all subscriptions...");
          // Resubscribe tất cả subscriptions
          _resubscribeAll();
          
          print("✅ [StompService] Calling onConnect callback...");
          print("✅ [StompService] _onConnectCallback is null: ${_onConnectCallback == null}");
          // Gọi callback
          if (_onConnectCallback != null) {
            print("✅ [StompService] Calling _onConnectCallback...");
            _onConnectCallback!(frame);
            print("✅ [StompService] _onConnectCallback completed");
          } else {
            print("❌ [StompService] _onConnectCallback is null!");
          }
          print("✅ [StompService] ====== CONNECT COMPLETE ======");
        },
        beforeConnect: () async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
        onStompError: (frame) {
          print("❌ [StompService] ====== STOMP ERROR ======");
          print("❌ [StompService] Error frame: $frame");
          _handleConnectionError();
        },
        onWebSocketError: (dynamic error) {
          print("❌ [StompService] ====== WEBSOCKET ERROR ======");
          print("❌ [StompService] Error: $error");
          _handleConnectionError();
          if (_onErrorCallback != null) {
            _onErrorCallback!(error);
          }
        },
        onDisconnect: (_) {
          _connected = false;
          _isConnecting = false;
          _heartbeatTimer?.cancel();
          
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

    print("🔄 [StompService] Activating StompClient...");
    _stompClient.activate();
    print("🔄 [StompService] StompClient activated");
  }
  
  /// Xử lý lỗi kết nối
  void _handleConnectionError() {
    print("❌ [StompService] ====== CONNECTION ERROR ======");
    print("❌ [StompService] _reconnectAttempts: $_reconnectAttempts");
    print("❌ [StompService] _maxReconnectAttempts: $_maxReconnectAttempts");
    
    _connected = false;
    _isConnecting = false;
    
    if (_reconnectAttempts < _maxReconnectAttempts) {
      print("🔄 [StompService] Scheduling reconnect...");
      _scheduleReconnect();
    } else {
      print("❌ [StompService] Max reconnect attempts reached, giving up");
    }
  }
  
  /// Lên lịch kết nối lại
  void _scheduleReconnect() {
    print("🔄 [StompService] ====== SCHEDULING RECONNECT ======");
    print("🔄 [StompService] Delay: $_reconnectDelay");
    print("🔄 [StompService] Current attempts: $_reconnectAttempts");
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      print("🔄 [StompService] Reconnect timer fired");
      print("🔄 [StompService] _connected: $_connected");
      print("🔄 [StompService] _reconnectAttempts: $_reconnectAttempts");
      
      if (!_connected && _reconnectAttempts < _maxReconnectAttempts) {
        print("🔄 [StompService] Attempting reconnect...");
        _connectInternal();
      } else {
        print("⚠️ [StompService] Reconnect conditions not met");
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
      // Silent fail for heartbeat
    }
  }
  
  /// Resubscribe tất cả subscriptions
  void _resubscribeAll() {
    print("🔄 [StompService] ====== RESUBSCRIBE ALL ======");
    print("🔄 [StompService] Number of subscriptions: ${_subscriptions.length}");
    _subscriptions.forEach((destination, callback) {
      print("🔄 [StompService] Resubscribing to: $destination");
      _subscribeInternal(destination, callback);
    });
    print("🔄 [StompService] ====== RESUBSCRIBE COMPLETE ======");
  }

  /// Subscribe tới một topic (chat hoặc call)
  void subscribe(String destination, void Function(dynamic parsed) callback) {
    print("🔔 [StompService] ====== SUBSCRIBE CALLED ======");
    print("🔔 [StompService] Destination: $destination");
    print("🔔 [StompService] Connected: $_connected");
    print("🔔 [StompService] Is connecting: $_isConnecting");
    print("🔔 [StompService] WebSocket URL: $_socketUrl");
    
    // Lưu subscription để resubscribe khi kết nối lại
    _subscriptions[destination] = callback;
    
    if (!_connected) {
      print("⚠️ [StompService] Not connected, will subscribe when connected");
      print("⚠️ [StompService] Subscription saved for later: $destination");
      return;
    }
    
    print("✅ [StompService] Calling _subscribeInternal...");
    _subscribeInternal(destination, callback);
  }
  
  /// Subscribe nội bộ
  void _subscribeInternal(String destination, void Function(dynamic parsed) callback) {
    print("🔔 [StompService] ====== SUBSCRIBE INTERNAL ======");
    print("🔔 [StompService] Destination: $destination");
    print("🔔 [StompService] StompClient active: ${_stompClient.connected}");

    _stompClient.subscribe(
      destination: destination,
      callback: (frame) {
        print("🔔 [StompService] ====== FRAME RECEIVED ======");
        print("🔔 [StompService] Destination: $destination");
        print("🔔 [StompService] Frame type: ${frame.runtimeType}");
        print("🔔 [StompService] Frame content: $frame");
        
        try {
          dynamic raw;

          // Trường hợp frame có body (StompFrame)
          if (frame is StompFrame) {
            print("🔔 [StompService] Frame is StompFrame");
            print("🔔 [StompService] Frame body: ${frame.body}");
            print("🔔 [StompService] Frame headers: ${frame.headers}");
            
            if (frame.body == null || frame.body!.isEmpty) {
              print("⚠️ [StompService] Empty frame body");
              return;
            }
            raw = jsonDecode(frame.body!);
          }
          // Trường hợp lib trả thẳng Map hoặc String
          else if (frame is String) {
            print("🔔 [StompService] Frame is String: $frame");
            raw = jsonDecode(frame as String);
          } else if (frame is Map<String, dynamic>) {
            print("🔔 [StompService] Frame is Map: $frame");
            raw = frame;
          } else {
            print("⚠️ [StompService] Unknown frame type: ${frame.runtimeType}");
            return;
          }

          print("🔔 [StompService] Parsed raw data: $raw");
          print("🔔 [StompService] Raw data type: ${raw.runtimeType}");

          // Trả về cho callback
          if (raw is Map<String, dynamic>) {
            print("✅ [StompService] Calling callback with parsed data");
            callback(raw);
          } else {
            print("❌ [StompService] Raw data is not Map<String, dynamic>");
          }
          print("🔔 [StompService] ====== END FRAME PROCESSING ======");
        } catch (e) {
          print("❌ [StompService] Error parsing frame: $e");
          print("❌ [StompService] Raw frame: $frame");
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
    _send(destination, signal);
  }

  /// Hàm private gửi dữ liệu chung
  void _send(String destination, Map<String, dynamic> body) {
    print("📤 [StompService] ====== SENDING DATA ======");
    print("📤 [StompService] Destination: $destination");
    print("📤 [StompService] Body: $body");
    print("📤 [StompService] Connected: $_connected");
    print("📤 [StompService] Is connecting: $_isConnecting");
    
    if (!_connected) {
      print("⚠️ [StompService] Not connected, attempting to reconnect...");
      // Thử kết nối lại nếu chưa đạt max attempts
      if (_reconnectAttempts < _maxReconnectAttempts) {
        _connectInternal();
      }
      return;
    }

    final jsonBody = jsonEncode(body);
    print("📤 [StompService] JSON body: $jsonBody");

    try {
      _stompClient.send(
        destination: destination,
        body: jsonBody,
      );
      print("✅ [StompService] Message sent successfully");
    } catch (e) {
      print("❌ [StompService] Error sending message: $e");
      _handleConnectionError();
    }
    print("📤 [StompService] ====== END SENDING DATA ======");
  }

  /// Ngắt kết nối
  void disconnect() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    
    if (_connected) {
      _stompClient.deactivate();
      _connected = false;
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
