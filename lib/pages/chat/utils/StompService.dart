import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

class StompService {
  late StompClient _stompClient;
  bool _connected = false;

  // Thay đổi IP theo backend của bạn
  static const String ipLocal = '192.168.1.7';
  final String _socketUrl = 'ws://$ipLocal:9999/ws';

  /// Khởi tạo kết nối STOMP
  void connect({
    required void Function(StompFrame frame) onConnect,
    void Function(dynamic error)? onError,
  }) {
    _stompClient = StompClient(
      config: StompConfig(
        url: _socketUrl,
        onConnect: (frame) {
          _connected = true;
          print("✅ STOMP connected: ${frame.headers}");
          onConnect(frame);
        },
        beforeConnect: () async {
          print('🔄 Connecting to STOMP...');
          await Future.delayed(const Duration(milliseconds: 200));
        },
        onStompError: (frame) {
          print('❌ STOMP error: ${frame.body}');
        },
        onWebSocketError: (dynamic error) {
          print('❌ WebSocket error: $error');
          if (onError != null) onError(error);
        },
        onDisconnect: (_) {
          _connected = false;
          print('🔌 Disconnected from STOMP');
        },
      ),
    );

    _stompClient.activate();
  }

  /// Subscribe tới một topic
  void subscribe(String destination, void Function(StompFrame frame) callback) {
    if (!_connected) {
      print('⚠️ Cannot subscribe, STOMP not connected');
      return;
    }
    print('🔔 Subscribing to $destination');
    _stompClient.subscribe(destination: destination, callback: callback);
  }

  /// Gửi tin nhắn (dùng cho cả 1-1 và group)
  void sendMessage(String destination, Map<String, dynamic> body) {
    if (!_connected) {
      print('⚠️ Cannot send, STOMP not connected');
      return;
    }

    final jsonBody = jsonEncode(body); // Chuyển thành JSON string
    print('📤 Sending message to $destination: $jsonBody');

    _stompClient.send(
      destination: destination,
      body: jsonBody,
    );
  }

  /// Ngắt kết nối
  void disconnect() {
    if (_connected) {
      _stompClient.deactivate();
      _connected = false;
      print('🔌 STOMP manually disconnected');
    }
  }
}
